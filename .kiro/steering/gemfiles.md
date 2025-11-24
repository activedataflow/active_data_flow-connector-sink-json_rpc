# Gemfile Guidelines

## Submoduler Dependencies

### Parent Gem (active_data_flow)

The active_data_flow gem includes in its Gemfile:

```ruby
gem 'submoduler-core-submoduler_parent', git: 'https://github.com/magenticmarketactualskill/submoduler-core-submoduler_child.git'
```

### Submodules (active_data_flow-*)

Each submodule with a name that starts with 'active_data_flow-' includes in its Gemfile:

```ruby
gem 'submoduler-core-submoduler_child', git: 'https://github.com/magenticmarketactualskill/submoduler-core-submoduler_child.git'
```

**Note**: Submodules use `submoduler_child` (not `submoduler_parent`)

## Submodule Path References

The active_data_flow gem includes in its Gemfile path references to submodules for local development:

```ruby
# Example submodule references
gem 'active_data_flow-connector-source-active_record', path: 'submodules/active_data_flow-connector-source-active_record'
gem 'active_data_flow-connector-sink-active_record', path: 'submodules/active_data_flow-connector-sink-active_record'
gem 'active_data_flow-runtime-heartbeat', path: 'submodules/active_data_flow-runtime-heartbeat'
```

## Bundle Context

The `bundle` command should work in two contexts:

1. **Parent gem context** (`active_data_flow/`)
   - Includes submoduler_parent
   - Includes path references to submodules

2. **Submodule context** (`submodules/active_data_flow-*/`)
   - Includes submoduler_child
   - Includes gemspec reference

## Standard Submodule Gemfile Template

```ruby
# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Submoduler child gem
gem 'submoduler-core-submoduler_child', git: 'https://github.com/magenticmarketactualskill/submoduler-core-submoduler_child.git'

gemspec
```

## Notes

- Parent uses `submoduler_parent`, submodules use `submoduler_child`
- All submodules should include `gemspec` to load dependencies from their gemspec file
- Path references in parent Gemfile enable local development without publishing gems