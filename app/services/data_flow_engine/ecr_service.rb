require 'aws-sdk-ecr'

module DataFlowEngine
  class EcrService
    attr_reader :data_flow

    def initialize(data_flow)
      @data_flow = data_flow
      @client = Aws::ECR::Client.new
    end

    # Create ECR repository
    def create_repository(repository_name = nil)
      repo_name = repository_name || default_repository_name

      response = @client.create_repository({
        repository_name: repo_name,
        image_scanning_configuration: {
          scan_on_push: true
        },
        encryption_configuration: {
          encryption_type: 'AES256'
        },
        tags: [
          {
            key: 'ManagedBy',
            value: 'ActiveDataFlow'
          },
          {
            key: 'DataFlow',
            value: data_flow.name
          }
        ]
      })

      {
        success: true,
        repository_uri: response.repository.repository_uri,
        repository_arn: response.repository.repository_arn,
        repository_name: response.repository.repository_name
      }
    rescue Aws::ECR::Errors::RepositoryAlreadyExistsException
      # Repository exists, get its details
      get_repository(repo_name)
    rescue Aws::ECR::Errors::ServiceError => e
      { success: false, error: e.message }
    end

    # Get repository details
    def get_repository(repository_name = nil)
      repo_name = repository_name || default_repository_name

      response = @client.describe_repositories({
        repository_names: [repo_name]
      })

      repository = response.repositories.first

      {
        success: true,
        repository_uri: repository.repository_uri,
        repository_arn: repository.repository_arn,
        repository_name: repository.repository_name
      }
    rescue Aws::ECR::Errors::ServiceError => e
      { success: false, error: e.message }
    end

    # Get authorization token for Docker login
    def get_authorization_token
      response = @client.get_authorization_token

      auth_data = response.authorization_data.first

      {
        success: true,
        authorization_token: auth_data.authorization_token,
        proxy_endpoint: auth_data.proxy_endpoint,
        expires_at: auth_data.expires_at
      }
    rescue Aws::ECR::Errors::ServiceError => e
      { success: false, error: e.message }
    end

    # Push image to ECR (returns instructions)
    def push_image_instructions(repository_name = nil, tag = 'latest')
      repo_result = create_repository(repository_name)
      return repo_result unless repo_result[:success]

      auth_result = get_authorization_token
      return auth_result unless auth_result[:success]

      repository_uri = repo_result[:repository_uri]
      
      {
        success: true,
        repository_uri: repository_uri,
        instructions: {
          login: "aws ecr get-login-password --region #{aws_region} | docker login --username AWS --password-stdin #{auth_result[:proxy_endpoint]}",
          build: "docker build -t #{repository_uri}:#{tag} .",
          push: "docker push #{repository_uri}:#{tag}"
        },
        full_image_uri: "#{repository_uri}:#{tag}"
      }
    end

    # List images in repository
    def list_images(repository_name = nil)
      repo_name = repository_name || default_repository_name

      response = @client.list_images({
        repository_name: repo_name
      })

      {
        success: true,
        images: response.image_ids.map { |img|
          {
            image_digest: img.image_digest,
            image_tag: img.image_tag
          }
        }
      }
    rescue Aws::ECR::Errors::ServiceError => e
      { success: false, error: e.message }
    end

    # Get image URI for Lambda
    def get_image_uri(repository_name = nil, tag = 'latest')
      repo_result = get_repository(repository_name)
      return repo_result unless repo_result[:success]

      {
        success: true,
        image_uri: "#{repo_result[:repository_uri]}:#{tag}"
      }
    end

    # Delete repository
    def delete_repository(repository_name = nil, force: false)
      repo_name = repository_name || default_repository_name

      @client.delete_repository({
        repository_name: repo_name,
        force: force
      })

      {
        success: true,
        message: "Repository #{repo_name} deleted"
      }
    rescue Aws::ECR::Errors::ServiceError => e
      { success: false, error: e.message }
    end

    # Build and push Docker image for Go/Rust Lambda functions
    def build_and_push_lambda_image(lambda_configuration, tag = 'latest')
      # Create repository
      repo_result = create_repository("#{data_flow.name}-#{lambda_configuration.code_language}")
      return repo_result unless repo_result[:success]

      repository_uri = repo_result[:repository_uri]

      # Generate Dockerfile
      dockerfile_content = generate_dockerfile(lambda_configuration)

      {
        success: true,
        repository_uri: repository_uri,
        image_uri: "#{repository_uri}:#{tag}",
        dockerfile: dockerfile_content,
        build_instructions: build_instructions(lambda_configuration, repository_uri, tag)
      }
    end

    private

    # Default repository name
    def default_repository_name
      "activedataflow/#{data_flow.name.parameterize}"
    end

    # Get AWS region
    def aws_region
      ActiveDataFlow.configuration.aws_region
    end

    # Generate Dockerfile for Lambda function
    def generate_dockerfile(lambda_configuration)
      case lambda_configuration.code_language
      when 'go'
        generate_go_dockerfile
      when 'rust'
        generate_rust_dockerfile
      else
        raise "Unsupported language for container: #{lambda_configuration.code_language}"
      end
    end

    # Generate Go Dockerfile
    def generate_go_dockerfile
      <<~DOCKERFILE
        FROM golang:1.21 AS builder
        WORKDIR /app
        COPY go.mod go.sum ./
        RUN go mod download
        COPY . .
        RUN CGO_ENABLED=0 GOOS=linux go build -o bootstrap main.go

        FROM public.ecr.aws/lambda/provided:al2023
        COPY --from=builder /app/bootstrap /var/runtime/bootstrap
        CMD ["bootstrap"]
      DOCKERFILE
    end

    # Generate Rust Dockerfile
    def generate_rust_dockerfile
      <<~DOCKERFILE
        FROM rust:1.75 AS builder
        WORKDIR /app
        COPY Cargo.toml Cargo.lock ./
        COPY src ./src
        RUN cargo build --release --target x86_64-unknown-linux-musl

        FROM public.ecr.aws/lambda/provided:al2023
        COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/bootstrap /var/runtime/bootstrap
        CMD ["bootstrap"]
      DOCKERFILE
    end

    # Build instructions for container image
    def build_instructions(lambda_configuration, repository_uri, tag)
      {
        step_1: "Create Dockerfile with the provided content",
        step_2: "Authenticate Docker to ECR: aws ecr get-login-password --region #{aws_region} | docker login --username AWS --password-stdin #{repository_uri.split('/').first}",
        step_3: "Build image: docker build -t #{repository_uri}:#{tag} .",
        step_4: "Push image: docker push #{repository_uri}:#{tag}",
        step_5: "Update Lambda function to use image: #{repository_uri}:#{tag}"
      }
    end
  end
end
