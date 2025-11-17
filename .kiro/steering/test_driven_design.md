# Test-Driven Design Guidelines

When designing with tests:

## Testing Framework

Use RSpec for all tests (see `.kiro/steering/tech.md`)

## Test Organization

```
gem_name/
├── lib/
│   └── component.rb
└── spec/
    ├── spec_helper.rb
    └── component_spec.rb
```

## Test Structure

- **Unit tests**: Test individual classes in isolation
- **Integration tests**: Test component interactions
- **System tests**: Test end-to-end flows (for Rails engine)

## RSpec Conventions

- Use `describe` for classes/modules
- Use `context` for different scenarios
- Use `it` for specific behaviors
- Use `let` for test data setup
- Use `before` for common setup

## Test Coverage

- Focus on core functionality, not edge cases
- Test public interfaces, not private methods
- Test error handling and validation
- Mock external dependencies (databases, APIs)

## Example Structure

```ruby
RSpec.describe ActiveDataflow::Connector::Source do
  describe '#each' do
    context 'when source has data' do
      it 'yields each record' do
        # test implementation
      end
    end
    
    context 'when source is empty' do
      it 'does not yield' do
        # test implementation
      end
    end
  end
end
```

See: `.kiro/steering/tech.md` for RSpec configuration
