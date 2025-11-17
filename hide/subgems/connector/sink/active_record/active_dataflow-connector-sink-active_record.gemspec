# frozen_string_literal: true

require_relative "lib/active_data_flow/active_record/version"

Gem::Specification.new do |spec|
  spec.name = "active_dataflow-connector-active_record"
  spec.version = ActiveDataFlow::ActiveRecord::VERSION
  spec.authors = ["ActiveDataFlow Team"]
  spec.email = ["team@activedataflow.dev"]

  spec.summary = "ActiveRecord connector for ActiveDataFlow"
  spec.description = "Provides ActiveRecord source and sink connectors for the ActiveDataFlow framework"
  spec.homepage = "https://github.com/magenticmarketactualskill/active_dataflow-connector-active_record"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.glob("{lib}/**/*") + %w[README.md LICENSE.txt CHANGELOG.md]
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "active_data_flow-core-core", "~> 0.1"
  spec.add_dependency "activerecord", ">= 6.0"
  spec.add_dependency "activesupport", ">= 6.0"

  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "sqlite3", "~> 1.4"
  spec.add_development_dependency "rubocop", "~> 1.50"
end
