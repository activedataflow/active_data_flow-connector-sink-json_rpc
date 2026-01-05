# frozen_string_literal: true

require_relative "lib/active_data_flow/connector/sink/json_rpc/version"

Gem::Specification.new do |spec|
  spec.name = "active_data_flow-connector-sink-json_rpc"
  spec.version = ActiveDataFlow::Connector::Sink::JsonRpc::VERSION
  spec.authors = ["ActiveDataFlow Team"]
  spec.email = ["team@activedataflow.dev"]

  spec.summary = "JSON-RPC sink connector for ActiveDataFlow"
  spec.description = "Provides a JSON-RPC client sink connector for ActiveDataFlow that sends data via JSON-RPC calls"
  spec.homepage = "https://github.com/magenticmarketactualskill/active_data_flow-connector-sink-json_rpc"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.6"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.glob("{lib}/**/*") + %w[README.md LICENSE.txt CHANGELOG.md]
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "jimson", "~> 0.10"
  spec.add_dependency "activesupport", ">= 6.0"
  spec.add_dependency "active_data_flow", ">= 0.1"
  spec.add_dependency "active_data_flow-connector-json_rpc", "~> 0.1"

  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "cucumber", "~> 9.0"
  spec.add_development_dependency "webmock", "~> 3.18"
end
