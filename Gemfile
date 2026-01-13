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

# Optional dependencies for testing consolidated modules
gem 'jimson', '~> 0.10'  # Required for JSON-RPC connectors


gem 'rainbow', '~> 3.0'
gem 'octokit', '~> 4.0'
gem 'inifile', '~> 3.0'

gem 'redis-emulator', path: './vendor/redis-emulator'
gem 'redcord', '~> 0.2.2'
gem 'tree-meta', path: './vendor/thor-concerns'
gem 'git-template', path: './vendor/git-template'
gem 'file-set', path: './vendor/file-set'
