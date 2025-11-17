# Gem Design Guidelines

When designing gems in the ActiveDataflow suite:

## Structure

- **Core gem** (`active_data_flow`): Placeholder modules in `lib/`, Rails engine integration
- **Subgems** (in `subgems/`): Concrete implementations managed in same repo

## Gem Organization

Each subgem follows this structure:

```
subgems/component/type/name/
├── lib/
│   └── active_data_flow/
│       └── component/
│           └── type/
│               └── name.rb
├── spec/
│   ├── spec_helper.rb
│   └── name_spec.rb
├── .kiro/
│   └── specs/
│       ├── requirements.md
│       ├── design.md
│       └── tasks.md
├── active_data_flow-component-type-name.gemspec
├── Gemfile
└── README.md
```

## Naming Conventions

- **Gem names**: `active_data_flow-{component}-{type}-{name}`
  - Example: `active_data_flow-connector-source-active_record`
- **Module names**: `ActiveDataflow::{Component}::{Type}::{Name}`
  - Example: `ActiveDataflow::Connector::Source::ActiveRecord`
- **File paths**: Match module structure
  - Example: `lib/active_data_flow/connector/source/active_record.rb`

## Design Principles

1. **Single Responsibility** - Each gem does one thing well
2. **Dependency Direction** - Subgems depend on core, never the reverse
3. **Configuration** - Accept configuration hashes, validate on initialization
4. **Error Handling** - Graceful failures with helpful error messages
5. **Testing** - RSpec tests for all public interfaces

## Gemspec Requirements

Each subgem gemspec should:
- Depend on the core `active_data_flow` gem
- Specify Ruby version (2.7+)
- Include development dependencies (rspec, bundler)
- Define clear summary and description
- List required runtime dependencies

## Example Gemspec

```ruby
Gem::Specification.new do |spec|
  spec.name          = "active_data_flow-connector-source-active_record"
  spec.version       = "0.1.0"
  spec.authors       = ["Your Name"]
  spec.summary       = "ActiveRecord source connector for ActiveDataflow"
  
  spec.files         = Dir["lib/**/*"]
  spec.require_paths = ["lib"]
  
  spec.required_ruby_version = ">= 2.7.0"
  
  spec.add_dependency "active_data_flow", "~> 0.1"
  spec.add_dependency "activerecord", ">= 6.0"
  
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "bundler"
end
```

See: `.kiro/steering/structure.md` for project structure
See: `.kiro/steering/product.md` for component types
See: `.kiro/steering/test_driven_design.md` for testing guidelines
