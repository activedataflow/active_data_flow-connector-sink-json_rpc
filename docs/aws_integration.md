## AWS Integration

ActiveDataFlow is designed to provide seamless integration with a variety of AWS services. This guide details how to configure and use each supported service within your DataFlow objects.

### AWS Lambda

ActiveDataFlow supports deploying Lambda functions written in Ruby, Go, and Rust. You can define your Lambda function in the `configure` block of your DataFlow class.

#### Configuration

```ruby
configure do |config|
  config.lambda_function(
    code_language: 'ruby', # 'ruby', 'go', or 'rust'
    runtime: 'ruby3.2', # Or 'provided.al2023' for Go/Rust
    handler: 'handler.process', # For Ruby. For Go/Rust, this is the binary name.
    memory_size: 512, # In MB
    timeout: 30, # In seconds
    environment_variables: {
      'LOG_LEVEL' => 'info'
    },
    function_code: <<~RUBY
      def process(event:, context:)
        # Your code here
      end
    RUBY
  )
end
```

-   **`code_language`**: Specifies the language of your Lambda function.
-   **`runtime`**: The AWS Lambda runtime to use.
-   **`handler`**: The method or binary that Lambda will execute.
-   **`function_code`**: The source code for your Lambda function. For simple Ruby scripts, you can embed the code directly. For Go and Rust, you would typically load the code from a file.

#### Multi-Language Support

-   **Ruby**: The `function_code` is packaged into a ZIP file and deployed.
-   **Go & Rust**: ActiveDataFlow's `CodeBuilderService` compiles your code, creates a `bootstrap` binary, and packages it for the `provided.al2023` runtime. This requires that you have the Go or Rust toolchain installed in your development environment.

### Amazon MSK (Managed Streaming for Apache Kafka)

Define and manage MSK clusters and topics directly from your DataFlow objects.

#### Configuration

```ruby
configure do |config|
  config.kafka_cluster(
    instance_type: 'kafka.m5.large',
    number_of_broker_nodes: 3,
    kafka_version: '3.5.1'
  )

  config.kafka_topics ['orders.created', 'orders.shipped', 'orders.delivered']
end
```

-   **`kafka_cluster`**: A hash of properties for creating the MSK cluster.
-   **`kafka_topics`**: An array of topic names to be created within the cluster.

### Amazon API Gateway

Create and configure HTTP APIs that can trigger your Lambda functions or other AWS services.

#### Configuration

```ruby
configure do |config|
  config.api_gateway(
    api_name: 'OrdersAPI',
    stage_name: 'v1',
    routes: [
      {
        route_key: 'POST /orders',
        integration_type: 'AWS_PROXY',
        integration_uri: 'lambda_function_arn' # Placeholder for the Lambda ARN
      },
      {
        route_key: 'GET /orders/{orderId}',
        integration_type: 'AWS_PROXY',
        integration_uri: 'lambda_function_arn'
      }
    ]
  )
end
```

-   **`api_name`**: The name of your API Gateway.
-   **`stage_name`**: The deployment stage (e.g., 'v1', 'production').
-   **`routes`**: An array of route definitions. The `integration_uri` can be a placeholder like `'lambda_function_arn'`, which ActiveDataFlow will automatically replace with the ARN of the Lambda function defined in the same DataFlow.

### AWS CloudFormation

For more complex infrastructure, you can provide a CloudFormation template. ActiveDataFlow will create or update the stack as part of the `push` operation.

#### Configuration

```ruby
configure do |config|
  config.cloudformation_template File.read(Rails.root.join('config', 'aws', 'my_stack.yml'))
end
```

When you provide a `cloudformation_template`, ActiveDataFlow will manage the entire lifecycle of the stack, including creation, updates, and deletion.

### Amazon ECR (Elastic Container Registry)

For container-based Lambda functions (written in Go or Rust), ActiveDataFlow can manage ECR repositories.

#### Configuration

```ruby
configure do |config|
  config.ecr_repository(
    repository_name: 'my-lambda-images'
  )
end
```

The `EcrService` provides methods to get build and push instructions for your Docker images, making it easier to integrate with your CI/CD pipeline.

## Sync Operations

ActiveDataFlow provides three main operations for synchronizing your configuration with AWS:

-   **`push!`**: Pushes the configuration from your database to AWS, creating or updating resources.
-   **`pull!`**: Pulls the current state of your resources from AWS and updates your database.
-   **`sync!`**: Performs a `pull!` followed by a `push!` to ensure a consistent state.

These operations can be triggered from the automatically generated API endpoints or directly from your code:

```ruby
# From your Rails console or another part of your application
UserOnboardingFlow.push!
```
