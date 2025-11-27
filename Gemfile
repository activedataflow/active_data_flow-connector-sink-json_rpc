# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Submoduler parent gem
gem 'submoduler-submoduler_parent', path: 'vendor/submoduler_parent'

# Load dependencies from gemspec
gemspec

# Submodule path overrides for local development
gem 'active_data_flow-connector-source-active_record', path: 'submodules/active_data_flow-connector-source-active_record'
gem 'active_data_flow-connector-sink-active_record', path: 'submodules/active_data_flow-connector-sink-active_record'
gem 'active_data_flow-runtime-heartbeat', path: 'submodules/active_data_flow-runtime-heartbeat'
gem 'active_data_flow-runtime-redcord', path: 'submodules/active_data_flow-runtime-redcord'
gem 'rainbow', '~> 3.0'
gem 'octokit', '~> 4.0'
gem 'inifile', '~> 3.0'

