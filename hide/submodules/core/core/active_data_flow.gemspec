# frozen_string_literal: true

require_relative "lib/active_data_flow/version"

Gem::Specification.new do |spec|
  spec.name = "active_data_flow-core-core"
  spec.version = ActiveDataFlow::VERSION
  spec.authors = ["ActiveDataFlow Team"]
  spec.email = ["team@activedataflow.dev"]

  spec.summary = "Core abstractions for ActiveDataFlow stream processing framework"
  spec.description = "Core abstractions and interfaces for building pluggable data processing pipelines in the ActiveDataFlow framework"
  spec.homepage = "https://github.com/activedataflow/active_data_flow-core-core"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.glob("{lib}/**/*") + %w[README.md LICENSE.txt CHANGELOG.md]
  spec.require_paths = ["lib"]

  # No runtime dependencies - pure Ruby
  
  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rubocop", "~> 1.50"
end
