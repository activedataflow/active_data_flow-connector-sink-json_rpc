# ActiveDataFlow ActiveRecord Connector

A connector gem for ActiveDataFlow that provides Source and Sink implementations for reading from and writing to Rails database tables using ActiveRecord.
xtop
## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_data_flow-active_record'
```

## Features

### Sink (Writing Data)

- **Single and Batch Writes**: Write records one at a time or buffer them for batch inserts
- **Upsert Support**: Update existing records or insert new ones with conflict resolution
- **Transaction Management**: Wrap writes in database transactions for consistency
- **Performance Optimizations**: Skip validations and callbacks for trusted data
- **Error Handling**: Graceful handling of validation errors and unique constraint violations

### Source (Reading Data)

- **Flexible Querying**: Filter, order, limit, and select specific columns
- **Batch Reading**: Process large datasets efficiently with configurable batch sizes
- **Streaming Support**: Iterate through records without loading everything into memory
- **Eager Loading**: Avoid N+1 queries with association preloading
- **Readonly Mode**: Mark records as readonly for performance

## Usage

### Sink Example

```ruby
# Simple write
sink = ActiveDataFlow::Sink::ActiveRecord.new(model_name: 'User')
sink.write({ name: 'John Doe', email: 'john@example.com' })

# Batch writes
sink = ActiveDataFlow::Sink::ActiveRecord.new(
  model_name: 'User',
  batch_size: 1000
)

users.each do |user|
  sink.write(user)
end
sink.close # Flush remaining records

# Upsert mode
sink = ActiveDataFlow::Sink::ActiveRecord.new(
  model_name: 'User',
  batch_size: 1000,
  upsert: true,
  unique_by: :email,
  update_only: [:name, :updated_at]
)

# With transactions
sink = ActiveDataFlow::Sink::ActiveRecord.new(
  model_name: 'User',
  batch_size: 1000,
  transaction: true
)
```

### Source Example

```ruby
# Simple read
source = ActiveDataFlow::Source::ActiveRecord.new(model_name: 'User')
source.each do |user|
  puts user.name
end

# With filtering and ordering
source = ActiveDataFlow::Source::ActiveRecord.new(
  model_name: 'User',
  where: { active: true },
  order: 'created_at DESC',
  limit: 100
)

# Batch reading for large datasets
source = ActiveDataFlow::Source::ActiveRecord.new(
  model_name: 'User',
  batch_size: 1000,
  select: [:id, :name, :email],
  readonly: true
)

source.each do |user|
  # Process user
end
```

## Configuration Options

### Sink Options

- `model_name` (required): ActiveRecord model class name
- `batch_size`: Number of records to buffer before batch insert
- `upsert`: Enable upsert mode (default: false)
- `unique_by`: Column(s) for conflict detection in upsert mode
- `update_only`: Columns to update in upsert mode
- `transaction`: Wrap writes in transactions (default: false)
- `skip_callbacks`: Disable ActiveRecord callbacks (default: false)
- `skip_validations`: Disable validations (default: false)

### Source Options

- `model_name` (required): ActiveRecord model class name
- `batch_size`: Number of records per batch (default: 1000)
- `where`: Filter conditions (hash or string)
- `order`: Sort order (string or hash)
- `limit`: Maximum number of records
- `select`: Columns to select (array)
- `includes`: Associations to eager load (array)
- `readonly`: Mark records as readonly (default: true)

## Testing

Run the test suite:

```bash
bundle exec rspec
```

## License

MIT
