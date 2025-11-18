# Gemfile Guidelines

## Submoduler Dependencies

### Parent Gem (active_data_flow)

The active_data_flow gem includes in its Gemfile:

```ruby
gem 'submoduler-core-submoduler_parent', git: 'https://github.com/magenticmarketactualskill/submoduler-core-submoduler_child.git'
```

### Subgems (active_data_flow-*)

Each subgem or submodule with a name that starts with 'active_data_flow-' includes in its Gemfile:

```ruby
gem 'submoduler-core-submoduler_child', git: 'https://github.com/magenticmarketactualskill/submoduler-core-submoduler_child.git'
```

**Note**: Subgems use `submoduler_child` (not `submoduler_parent`)

## Subgem Path References

The active_data_flow gem includes in its Gemfile path references to subgems for local development:

```ruby
# Example subgem references
gem 'active_data_flow-connector-source-active_record', path: 'subgems/active_data_flow-connector-source-active_record'
gem 'active_data_flow-connector-sink-active_record', path: 'subgems/active_data_flow-connector-sink-active_record'
gem 'active_data_flow-runtime-heartbeat', path: 'subgems/active_data_flow-runtime-heartbeat'
```

## Bundle Context

The `bundle` command should work in three contexts:

1. **Parent gem context** (`active_data_flow/`)
   - Includes submoduler_parent
   - Includes path references to subgems

2. **Subgem context** (`subgems/active_data_flow-*/`)
   - Includes submoduler_child
   - Includes gemspec reference

3. **Submodule context** (external repos)
   - Includes submoduler_child
   - Includes gemspec reference

## Standard Subgem Gemfile Template

```ruby
# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Submoduler child gem
gem 'submoduler-core-submoduler_child', git: 'https://github.com/magenticmarketactualskill/submoduler-core-submoduler_child.git'

gemspec
```

## Notes

- Parent uses `submoduler_parent`, subgems use `submoduler_child`
- All subgems should include `gemspec` to load dependencies from their gemspec file
- Path references in parent Gemfile enable local development without publishing gems