require 'cucumber/rails'
require 'factory_bot_rails'
require 'database_cleaner/active_record'

World(FactoryBot::Syntax::Methods)

DatabaseCleaner.strategy = :truncation

Around do |scenario, block|
  DatabaseCleaner.cleaning(&block)
end

# Stub AWS calls in Cucumber tests
Before do
  allow(Aws::Lambda::Client).to receive(:new).and_return(
    Aws::Lambda::Client.new(stub_responses: true)
  )
  allow(Aws::Kafka::Client).to receive(:new).and_return(
    Aws::Kafka::Client.new(stub_responses: true)
  )
  allow(Aws::ApiGatewayV2::Client).to receive(:new).and_return(
    Aws::ApiGatewayV2::Client.new(stub_responses: true)
  )
end
