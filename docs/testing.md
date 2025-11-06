# Testing Guide

ActiveDataFlow is designed to be testable, and it comes with a testing framework that includes RSpec for unit and integration tests, and Cucumber for feature tests. When you generate the gem, a `spec` and `features` directory are created with a dummy Rails application to test the engine in isolation.

## Setting Up the Test Environment

Before running tests, you need to set up the test database:

```bash
$ cd /path/to/your/gem
$ bundle exec rake db:migrate
$ bundle exec rake db:test:prepare
```

## RSpec

RSpec is used for testing the individual components of the gem, such as models, services, and controllers.

### Running RSpec Tests

To run the entire RSpec suite:

```bash
$ bundle exec rspec
```

To run a specific file:

```bash
$ bundle exec rspec spec/models/data_flow_engine/data_flow_spec.rb
```

### Writing Specs

-   **Models**: Test validations, associations, scopes, and instance methods.
-   **Services**: Test the interaction with the AWS SDK. It is highly recommended to use mocks to avoid making actual AWS calls in your tests. The `aws-sdk-lambda` gem, for example, provides a `stub_responses` feature that is perfect for this.
-   **Controllers**: Test the API endpoints, including response codes, JSON structure, and authorization.

### Example: Stubbing AWS Calls

Here is an example of how to test the `LambdaService` by stubbing the AWS SDK client:

```ruby
# spec/services/data_flow_engine/lambda_service_spec.rb
require 'rails_helper'

RSpec.describe DataFlowEngine::LambdaService do
  let(:data_flow) { create(:data_flow) }
  let(:lambda_config) { create(:lambda_configuration, data_flow: data_flow) }
  let(:service) { described_class.new(lambda_config) }
  let(:aws_client) { Aws::Lambda::Client.new(stub_responses: true) }

  before do
    allow(Aws::Lambda::Client).to receive(:new).and_return(aws_client)
  end

  describe '#deploy' do
    it 'creates a new function if not deployed' do
      aws_client.stub_responses(:create_function, { function_arn: 'arn:aws:lambda:us-east-1:123456789012:function:my-function' })
      
      result = service.deploy
      expect(result[:success]).to be true
      expect(result[:function_arn]).to include('my-function')
    end
  end
end
```

## Cucumber

Cucumber is used for writing high-level feature tests that simulate how a user would interact with the gem's features.

### Running Cucumber Features

To run all Cucumber features:

```bash
$ bundle exec cucumber
```

To run a specific feature:

```bash
$ bundle exec cucumber features/data_flows/manage_data_flows.feature
```

### Writing Features

Cucumber features are written in Gherkin syntax and should describe a specific feature from the user's perspective. The step definitions will then use tools like Capybara (for UI testing, if you add a UI) or Rack::Test to make requests to your engine's API endpoints.

### Example Feature

```gherkin
# features/data_flows/manage_data_flows.feature
Feature: Manage DataFlows

  Scenario: Create a new DataFlow
    When I send a POST request to "/dataflow" with the following:
      | name        | description         |
      | my-new-flow | A brand new data flow |
    Then the response status should be "201"
    And the JSON response should have "name" with the value "my-new-flow"
```

## Continuous Integration

It is recommended to run your tests in a CI environment like GitHub Actions. Here is an example workflow that runs both RSpec and Cucumber tests:

```yaml
# .github/workflows/ci.yml
name: CI

on: [push]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v2

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.3.6

      - name: Install dependencies
        run: bundle install

      - name: Set up database
        run: |
          bundle exec rake db:migrate
          bundle exec rake db:test:prepare

      - name: Run tests
        run: bundle exec rake
```
