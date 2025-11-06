_# Creating DataFlow Objects

DataFlow objects are the core of ActiveDataFlow. They are Ruby classes that encapsulate the logic and configuration for a specific data flow. By creating a class that inherits from `ActiveDataFlow::DataFlowBase`, you get automatic routing, database persistence, and a DSL for configuring AWS resources.

## Getting Started

To create a new DataFlow, add a new Ruby file in the `app/data_flow` directory of your Rails application. The file name should be the snake_case version of your class name.

For example, a class named `UserOnboardingFlow` should be in a file named `app/data_flow/user_onboarding_flow.rb`.

### Basic Structure

Here is the basic structure of a DataFlow class:

```ruby
# app/data_flow/user_onboarding_flow.rb
class UserOnboardingFlow < ActiveDataFlow::DataFlowBase
  # Configuration DSL
  configure do |config|
    config.description "Handles the entire user onboarding process"

    # ... AWS resource configuration ...
  end

  # Controller-like actions
  def process
    # Main logic for the data flow
    { status: 'ok', message: "User onboarding flow executed" }
  end

  def check_status
    # Custom action to provide status information
    {
      flow_status: self.class.data_flow_record.status,
      sync_status: self.class.data_flow_record.aws_sync_status
    }
  end
end
```

## Configuration DSL

The `configure` block provides a DSL to define the AWS resources and metadata associated with your data flow. This configuration is stored in the `data_flows` database table in a `jsonb` column.

### Available Configuration Methods

| Method                    | Argument(s)      | Description                                                                                                                            |
| ------------------------- | ---------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `description`             | `String`         | A human-readable description of the data flow.                                                                                         |
| `lambda_function`         | `Hash`           | Defines the configuration for an AWS Lambda function. See [AWS Integration Guide](aws_integration.md#lambda) for details.                |
| `kafka_topics`            | `Array<String>`  | A list of Kafka topic names to be created or managed.                                                                                  |
| `kafka_cluster`           | `Hash`           | Defines the configuration for an Amazon MSK cluster. See [AWS Integration Guide](aws_integration.md#msk) for details.                  |
| `api_gateway`             | `Hash`           | Defines the configuration for an Amazon API Gateway. See [AWS Integration Guide](aws_integration.md#api-gateway) for details.          |
| `cloudformation_template` | `String` or `Hash` | The path to a CloudFormation template file or the template body as a Hash.                                                             |
| `ecr_repository`          | `Hash`           | Defines the configuration for an Amazon ECR repository, typically used for container-based Lambda functions.                         |
| `metadata`                | `Hash`           | A hash for storing any custom metadata, such as owner, version, or links to documentation.                                             |

### Example Configuration

```ruby
configure do |config|
  config.description "Processes incoming user data and sends notifications"

  config.lambda_function(
    code_language: 'ruby',
    runtime: 'ruby3.2',
    handler: 'handler.process',
    memory_size: 512
  )

  config.kafka_topics ['user.created', 'user.updated']

  config.metadata(
    owner: 'Data Engineering Team',
    slack_channel: '#data-eng-alerts'
  )
end
```

## Automatic Routing

ActiveDataFlow automatically creates routes for your DataFlow objects based on their class name. The routes are mounted under the `base_route` you specified in the initializer.

A class named `UserOnboardingFlow` will be accessible at `/dataflow/user_onboarding_flow`.

### Default Actions

The base implementation provides several default actions that are exposed as API endpoints:

-   **`GET /:name`**: Shows the details and configuration of the data flow.
-   **`POST /:name/push`**: Pushes the current configuration to AWS.
-   **`POST /:name/pull`**: Pulls the latest configuration from AWS and updates the database.
-   **`POST /:name/sync`**: Performs a pull and then a push to synchronize the state.
-   **`GET /:name/status`**: Returns the current sync status of the data flow.

### Custom Actions

Any public instance method you define in your DataFlow class can be invoked via a corresponding route. For example, the `check_status` method in the example above would be accessible via:

`GET /dataflow/user_onboarding_flow/check_status`

This allows you to create controller-like actions to trigger specific logic within your data flow.

## Interacting with the DataFlow Record

Each DataFlow class is associated with a `DataFlowEngine::DataFlow` ActiveRecord model that stores its configuration and state in the database.

You can access this record from within your class methods using `self.class.data_flow_record`.

```ruby
def check_status
  record = self.class.data_flow_record
  {
    name: record.name,
    status: record.status,
    last_synced: record.last_synced_at
  }
end
```

This allows you to build custom actions that read from or write to the data flow's persistent state.
