# Configuration Guide

ActiveDataFlow provides a flexible configuration system that allows you to tailor its behavior to your application's needs. Configuration is primarily handled through an initializer file in your Rails application.

## Initializer

Create a new file at `config/initializers/active_data_flow.rb` in your Rails application to configure the gem:

```ruby
ActiveDataFlow.configure do |config|
  # AWS Configuration
  config.aws_region = 'us-east-1'
  config.aws_access_key_id = ENV['AWS_ACCESS_KEY_ID']
  config.aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']

  # Engine Configuration
  config.base_route = '/dataflow'
  config.enable_ui = true

  # Authorization
  config.authorization_method = :current_user_is_admin?
end
```

### Configuration Options

| Option                  | Type    | Description                                                                                                                              | Default                                  |
| ----------------------- | ------- | ---------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------- |
| `aws_region`            | String  | The AWS region to use for all service integrations.                                                                                      | `ENV['AWS_REGION']` or `'us-east-1'`     |
| `aws_access_key_id`     | String  | Your AWS access key ID. It's highly recommended to use environment variables for this.                                                   | `ENV['AWS_ACCESS_KEY_ID']`               |
| `aws_secret_access_key` | String  | Your AWS secret access key. It's highly recommended to use environment variables for this.                                                 | `ENV['AWS_SECRET_ACCESS_KEY']`           |
| `base_route`            | String  | The base path at which to mount the DataFlowEngine.                                                                                      | `'/dataflow'`                            |
| `enable_ui`             | Boolean | Whether to enable the built-in UI for managing data flows. (Future feature)                                                              | `true`                                   |
| `authorization_method`  | Symbol  | A method name (as a symbol) to be called in your `ApplicationController` to authorize access to the data flow engine's controllers. | `nil` (no authorization by default)      |

## Authorization

To protect your data flow endpoints, you can specify an authorization method in the configuration. This method will be called as a `before_action` in the engine's `ApplicationController`.

In your `ApplicationController` (or a parent controller), define the method you specified in the configuration:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  private

  def current_user_is_admin?
    # Your authorization logic here
    current_user&.admin?
  end
end
```

If the authorization method returns `false` or `nil`, ActiveDataFlow will render a `401 Unauthorized` response.

## AWS Credentials

ActiveDataFlow uses the official AWS SDK for Ruby. The SDK has a comprehensive chain of credential providers. It's recommended to manage AWS credentials using IAM roles when running on EC2 or ECS. For local development, you can set the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables.

## Per-Environment Configuration

You can also configure ActiveDataFlow differently for each environment (development, staging, production) by using Rails' standard environment configuration files (`config/environments/*.rb`).

For example, in `config/environments/development.rb`:

```ruby
Rails.application.configure do
  # ...

  ActiveDataFlow.configure do |config|
    config.base_route = '/dev/dataflow'
  end
end
```
