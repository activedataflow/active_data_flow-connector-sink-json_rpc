require 'aws-sdk-lambda'
require 'zip'
require 'base64'

module DataFlowEngine
  class LambdaService
    attr_reader :lambda_configuration

    def initialize(lambda_configuration)
      @lambda_configuration = lambda_configuration
      @client = Aws::Lambda::Client.new
    end

    # Deploy Lambda function (create or update)
    def deploy
      if lambda_configuration.deployed?
        update_function
      else
        create_function
      end
    rescue Aws::Lambda::Errors::ServiceError => e
      { success: false, error: e.message }
    end

    # Create new Lambda function
    def create_function
      deployment_package = build_deployment_package

      response = @client.create_function({
        function_name: lambda_configuration.function_name,
        runtime: lambda_configuration.runtime,
        role: get_or_create_execution_role,
        handler: lambda_configuration.handler,
        code: deployment_package,
        timeout: lambda_configuration.timeout,
        memory_size: lambda_configuration.memory_size,
        environment: {
          variables: lambda_configuration.environment_variables
        },
        description: "DataFlow Lambda: #{lambda_configuration.data_flow.name}"
      })

      {
        success: true,
        function_arn: response.function_arn,
        version: response.version,
        details: {
          function_name: response.function_name,
          runtime: response.runtime,
          code_size: response.code_size
        }
      }
    rescue Aws::Lambda::Errors::ServiceError => e
      { success: false, error: e.message }
    end

    # Update existing Lambda function
    def update_function
      update_function_code
      update_function_configuration
    rescue Aws::Lambda::Errors::ServiceError => e
      { success: false, error: e.message }
    end

    # Update function code
    def update_function_code
      deployment_package = build_deployment_package

      response = @client.update_function_code({
        function_name: lambda_configuration.aws_function_arn,
        zip_file: deployment_package[:zip_file]
      })

      {
        success: true,
        function_arn: response.function_arn,
        version: response.version
      }
    end

    # Update function configuration
    def update_function_configuration
      response = @client.update_function_configuration({
        function_name: lambda_configuration.aws_function_arn,
        runtime: lambda_configuration.runtime,
        handler: lambda_configuration.handler,
        timeout: lambda_configuration.timeout,
        memory_size: lambda_configuration.memory_size,
        environment: {
          variables: lambda_configuration.environment_variables
        }
      })

      {
        success: true,
        function_arn: response.function_arn
      }
    end

    # Get function details from AWS
    def get_function
      response = @client.get_function({
        function_name: lambda_configuration.aws_function_arn
      })

      {
        success: true,
        configuration: response.configuration.to_h,
        code: response.code.to_h
      }
    rescue Aws::Lambda::Errors::ServiceError => e
      { success: false, error: e.message }
    end

    # Delete function
    def delete_function
      @client.delete_function({
        function_name: lambda_configuration.aws_function_arn
      })

      { success: true }
    rescue Aws::Lambda::Errors::ServiceError => e
      { success: false, error: e.message }
    end

    private

    # Build deployment package based on language
    def build_deployment_package
      case lambda_configuration.code_language
      when 'ruby'
        build_ruby_package
      when 'go'
        build_go_package
      when 'rust'
        build_rust_package
      else
        raise "Unsupported language: #{lambda_configuration.code_language}"
      end
    end

    # Build Ruby deployment package
    def build_ruby_package
      zip_buffer = Zip::OutputStream.write_buffer do |zip|
        zip.put_next_entry('handler.rb')
        zip.write(lambda_configuration.function_code || default_ruby_handler)
      end

      {
        zip_file: zip_buffer.string
      }
    end

    # Build Go deployment package (requires compilation)
    def build_go_package
      # For Go, we would typically:
      # 1. Save the Go code to a temporary directory
      # 2. Compile it with GOOS=linux GOARCH=amd64
      # 3. Create a ZIP with the binary named 'bootstrap'
      
      # Simplified version - in production, this would compile actual Go code
      zip_buffer = Zip::OutputStream.write_buffer do |zip|
        zip.put_next_entry('main.go')
        zip.write(lambda_configuration.function_code || default_go_handler)
      end

      {
        zip_file: zip_buffer.string
      }
    end

    # Build Rust deployment package (requires compilation)
    def build_rust_package
      # For Rust, similar to Go:
      # 1. Save Rust code
      # 2. Compile with cargo build --release --target x86_64-unknown-linux-musl
      # 3. Create ZIP with binary named 'bootstrap'
      
      # Simplified version
      zip_buffer = Zip::OutputStream.write_buffer do |zip|
        zip.put_next_entry('main.rs')
        zip.write(lambda_configuration.function_code || default_rust_handler)
      end

      {
        zip_file: zip_buffer.string
      }
    end

    # Get or create IAM execution role for Lambda
    def get_or_create_execution_role
      # In production, this should create/fetch an actual IAM role
      # For now, return a placeholder that would need to be configured
      ENV['LAMBDA_EXECUTION_ROLE_ARN'] || 'arn:aws:iam::123456789012:role/lambda-execution-role'
    end

    # Default Ruby handler code
    def default_ruby_handler
      <<~RUBY
        def process(event:, context:)
          {
            statusCode: 200,
            body: JSON.generate({
              message: 'Hello from ActiveDataFlow Lambda',
              event: event
            })
          }
        end
      RUBY
    end

    # Default Go handler code
    def default_go_handler
      <<~GO
        package main

        import (
          "context"
          "github.com/aws/aws-lambda-go/lambda"
        )

        type Event struct {
          Name string `json:"name"`
        }

        func HandleRequest(ctx context.Context, event Event) (string, error) {
          return "Hello from ActiveDataFlow Lambda (Go)", nil
        }

        func main() {
          lambda.Start(HandleRequest)
        }
      GO
    end

    # Default Rust handler code
    def default_rust_handler
      <<~RUST
        use lambda_runtime::{service_fn, LambdaEvent, Error};
        use serde_json::{json, Value};

        async fn function_handler(event: LambdaEvent<Value>) -> Result<Value, Error> {
            Ok(json!({
                "message": "Hello from ActiveDataFlow Lambda (Rust)"
            }))
        }

        #[tokio::main]
        async fn main() -> Result<(), Error> {
            let func = service_fn(function_handler);
            lambda_runtime::run(func).await?;
            Ok(())
        }
      RUST
    end
  end
end
