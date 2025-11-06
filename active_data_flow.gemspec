require_relative "lib/active_data_flow/version"

Gem::Specification.new do |spec|
  spec.name        = "active_data_flow"
  spec.version     = ActiveDataFlow::VERSION
  spec.authors     = ["ActiveDataFlow Team"]
  spec.email       = ["team@activedataflow.com"]
  spec.homepage    = "https://github.com/activedataflow/active_data_flow"
  spec.summary     = "Rails Engine for managing data flow configurations with AWS integration"
  spec.description = "ActiveDataFlow implements a Rails Engine (DataFlowEngine) that provides a framework for defining, storing, and synchronizing data flow configurations across AWS services including Lambda, MSK (Kafka), CloudFormation, ECR, and API Gateway."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/activedataflow/active_data_flow"
  spec.metadata["changelog_uri"] = "https://github.com/activedataflow/active_data_flow/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.required_ruby_version = ">= 3.3.6"

  # Rails dependencies
  spec.add_dependency "rails", ">= 7.0.0"
  
  # AWS SDK dependencies
  spec.add_dependency "aws-sdk-lambda", "~> 1.0"
  spec.add_dependency "aws-sdk-kafka", "~> 1.0"
  spec.add_dependency "aws-sdk-cloudformation", "~> 1.0"
  spec.add_dependency "aws-sdk-ecr", "~> 1.0"
  spec.add_dependency "aws-sdk-apigatewayv2", "~> 1.0"
  
  # Development dependencies
  spec.add_development_dependency "rspec-rails", "~> 6.0"
  spec.add_development_dependency "cucumber-rails", "~> 3.0"
  spec.add_development_dependency "factory_bot_rails", "~> 6.0"
  spec.add_development_dependency "database_cleaner-active_record", "~> 2.0"
  spec.add_development_dependency "sqlite3", "~> 1.4"
  spec.add_development_dependency "pg", "~> 1.5"
end
