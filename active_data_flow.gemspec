# frozen_string_literal: true

require_relative "lib/active_data_flow/version"

Gem::Specification.new do |spec|
  spec.name = "active_data_flow"
  spec.version = ActiveDataFlow::VERSION
  spec.authors = ["ActiveDataFlow Team"]
  spec.email = ["team@activedataflow.dev"]

  spec.summary = "Modular stream processing framework for Ruby"
  spec.description = "A plugin-based stream processing framework inspired by Apache Flink. Provides abstract interfaces for sources, sinks, and runtimes with concrete implementations in separate gems."
  spec.homepage = "https://github.com/magenticmarketactualskill/active_data_flow"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.glob("{app,config,db,lib}/**/*") + %w[README.md]
  spec.require_paths = ["lib"]

  # Rails engine support
  spec.add_runtime_dependency "rails", ">= 6.0"

  # Core dependencies only - submodules are optional
  # spec.add_runtime_dependency "active_data_flow-connector-source-active_record"
  # spec.add_runtime_dependency "active_data_flow-connector-sink-active_record"
  # spec.add_runtime_dependency "active_data_flow-runtime-heartbeat"

  # Development dependencies
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rspec-rails", "~> 6.0"
  spec.add_development_dependency "sqlite3", ">= 1.4"
  spec.add_development_dependency "rubocop", "~> 1.50"
  
end
