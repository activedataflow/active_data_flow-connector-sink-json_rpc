# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Submoduler parent gem
gem 'submoduler-submoduler_parent', path: 'vendor/submoduler_parent'

# Load dependencies from gemspec
gemspec

gem 'git_steering', path: 'vendor/git_steering'
gem 'rung', path: './vendor/rung'
gem 'vendorer', path: 'vendor/vendorer'
gem 'forker', path: 'vendor/forker' 

# Submodule path overrides for local development
gem 'active_data_flow-connector-source-active_record', path: 'submodules/active_data_flow-connector-source-active_record'
gem 'active_data_flow-connector-sink-active_record', path: 'submodules/active_data_flow-connector-sink-active_record'
gem 'active_data_flow-runtime-heartbeat', path: 'submodules/active_data_flow-runtime-heartbeat'
gem 'active_data_flow-runtime-redcord', path: 'submodules/active_data_flow-runtime-redcord'

# New submodules (commented out due to dependency conflicts - submodules are available for development)
# gem 'active_data_flow-connector-active_record', path: 'submodules/active_data_flow-connector-active_record'
# gem 'active_data_flow-connector-json_rpc', path: 'submodules/active_data_flow-connector-json_rpc'
# gem 'active_data_flow-connector-sink-json_rpc', path: 'submodules/active_data_flow-connector-sink-json_rpc'
# gem 'active_data_flow-connector-source-json_rpc', path: 'submodules/active_data_flow-connector-source-json_rpc'
# gem 'active_data_flow-runtime-heartbeat_app', path: 'submodules/active_data_flow-runtime-heartbeat_app'


gem 'rainbow', '~> 3.0'
gem 'octokit', '~> 4.0'
gem 'inifile', '~> 3.0'

gem 'redis-emulator', path: './vendor/redis-emulator'
gem 'redcord', '~> 0.2.2'
gem 'tree-meta', path: './vendor/thor-concerns'
gem 'git-template', path: './vendor/git-template'
gem 'file-set', path: './vendor/file-set'
