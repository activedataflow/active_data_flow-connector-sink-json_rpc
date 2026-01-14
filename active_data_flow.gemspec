# frozen_string_literal: true

require_relative "lib/active_data_flow/version"

Gem::Specification.new do |spec|
  spec.name = "active_data_flow"
  spec.version = ActiveDataFlow::VERSION
  spec.authors = ["ActiveDataFlow Team"]
  spec.email = ["team@activedataflow.dev"]

  spec.summary = "Modular stream processing framework for Ruby"
  spec.description = <<~DESC
    A plugin-based stream processing framework for Ruby/Rails.
    Provides sources, sinks, and runtimes for data flow processing.
    Includes optional connectors for ActiveRecord and JSON-RPC,
    plus runtime implementations for heartbeat and Redcord backends.
  DESC
  spec.homepage = "https://github.com/activedataflow/active_data_flow"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.glob("{app,config,db,lib}/**/*") + %w[README.md]
  spec.require_paths = ["lib"]

  # === Core Dependencies (always required) ===
  spec.add_runtime_dependency "rails", ">= 6.0"
  spec.add_runtime_dependency "activesupport", ">= 6.0"
  spec.add_runtime_dependency "activerecord", ">= 6.0"
  spec.add_runtime_dependency "functional_task_supervisor"

  # === Optional Dependencies (documented, not enforced) ===
  # These are required only if using specific connectors/runtimes.
  # Users must add them to their own Gemfile.
  #
  # For JSON-RPC connectors:
  #   gem 'jimson', '~> 0.10'
  #
  # For Redcord runtime:
  #   gem 'redcord', '~> 0.2.2'

  # === Development Dependencies ===
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rspec-rails", "~> 6.0"
  spec.add_development_dependency "sqlite3", ">= 1.4"
  spec.add_development_dependency "rubocop", "~> 1.50"

  # Dev deps for optional features (testing all modules)
  spec.add_development_dependency "jimson", "~> 0.10"
  spec.add_development_dependency "webmock", "~> 3.18"
  spec.add_development_dependency "redcord", "~> 0.2.2"
end
