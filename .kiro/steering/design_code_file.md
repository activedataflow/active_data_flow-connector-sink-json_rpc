# Code File Design Guidelines

When designing Ruby code files:

## File Organization

- One class per file
- File path matches module structure: `lib/connector/source.rb` → `ActiveDataflow::Connector::Source`
- Use `require_relative` for internal dependencies

## Class Design

- **Base classes**: Define abstract interfaces with `raise NotImplementedError`
- **Concrete classes**: Implement all abstract methods
- **Modules**: Use for shared behavior (mixins)
- **Configuration**: Accept config hash in `initialize`, validate early

## Method Design

- **Public methods**: Document with comments, keep interface minimal
- **Private methods**: Extract complex logic, no documentation needed
- **Return values**: Be consistent (nil, false, or raise errors)

## Ruby Conventions

- Use 2-space indentation
- Follow Ruby community standards (Rubocop)
- Prefer `each` over `for`, blocks over lambdas for simple cases
- Use symbols for keys, strings for values

See: `.kiro/steering/tech.md` for Ruby version and dependencies
