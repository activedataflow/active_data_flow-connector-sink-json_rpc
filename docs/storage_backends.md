# Storage Backend Configuration

ActiveDataFlow supports multiple storage backends for persisting DataFlow and DataFlowRun models. This allows you to choose the best storage solution for your application's needs.

## Supported Backends

### 1. ActiveRecord (Default)

Uses your Rails database (PostgreSQL, MySQL, SQLite, etc.) for storage.

**Pros:**
- Default option, works out of the box
- Familiar Rails patterns
- Rich query capabilities
- ACID transactions
- Well-suited for complex queries and relationships

**Cons:**
- Requires database setup and migrations
- May be slower for high-frequency updates

**Setup:**

```ruby
# config/initializers/active_data_flow.rb
ActiveDataFlow.configure do |config|
  config.storage_backend = :active_record  # This is the default
end
```

Run migrations:
```bash
rails active_data_flow:install:migrations
rails db:migrate
```

### 2. Redcord with Redis

Uses a standard Redis server for storage via the Redcord gem.

**Pros:**
- Fast key-value storage
- Better for high-frequency updates
- Lower latency for simple operations
- Scales horizontally

**Cons:**
- Requires separate Redis server
- Limited query capabilities compared to SQL
- No built-in ACID transactions across multiple keys

**Setup:**

Add to Gemfile:
```ruby
gem 'redis'
gem 'redcord'
```

Configure:
```ruby
# config/initializers/active_data_flow.rb
ActiveDataFlow.configure do |config|
  config.storage_backend = :redcord_redis
  config.redis_config = {
    url: ENV['REDIS_URL'] || 'redis://localhost:6379/0'
    # OR specify individual options:
    # host: 'localhost',
    # port: 6379,
    # db: 0
  }
end
```

### 3. Redcord with Redis Emulator

Uses redis-emulator backed by Rails Solid Cache. No separate Redis server needed!

**Pros:**
- No separate Redis server required
- Uses Rails.cache (Solid Cache) as backing store
- Same Redcord interface as standard Redis
- Good for development and testing
- Simpler deployment

**Cons:**
- Performance depends on Rails.cache backend
- Not a true Redis implementation
- May have limitations compared to real Redis

**Setup:**

Add to Gemfile:
```ruby
gem 'redis-emulator'
gem 'redcord'
```

Configure:
```ruby
# config/initializers/active_data_flow.rb
ActiveDataFlow.configure do |config|
  config.storage_backend = :redcord_redis_emulator
  # Uses Rails.cache as backing store (configure in config/cache.yml)
end
```

## Choosing a Backend

### Use ActiveRecord when:
- You need complex queries and relationships
- You want ACID transactions
- You're already using a SQL database
- You need rich querying capabilities

### Use Redcord Redis when:
- You need high-frequency updates
- You want lower latency
- You're comfortable managing a Redis server
- You need horizontal scaling

### Use Redcord Redis Emulator when:
- You want Redis-like storage without a separate server
- You're in development/testing
- You want to simplify deployment
- You're already using Rails Solid Cache

## Migration Guide

### From ActiveRecord to Redcord

1. Export your data:
```ruby
# Create a migration script
DataFlow.find_each do |flow|
  # Save flow data to JSON or CSV
end
```

2. Change configuration:
```ruby
config.storage_backend = :redcord_redis  # or :redcord_redis_emulator
```

3. Import your data:
```ruby
# Load and recreate flows in new backend
```

### From Redcord to ActiveRecord

1. Export your data from Redis
2. Change configuration to `:active_record`
3. Run migrations
4. Import your data

## Performance Considerations

| Operation | ActiveRecord | Redcord Redis | Redcord Emulator |
|-----------|--------------|---------------|------------------|
| Simple reads | Good | Excellent | Good |
| Simple writes | Good | Excellent | Good |
| Complex queries | Excellent | Limited | Limited |
| Transactions | Excellent | Limited | Limited |
| Horizontal scaling | Moderate | Excellent | Moderate |

## Troubleshooting

### ActiveRecord Backend

**Issue:** Migrations not found
```bash
# Solution:
rails active_data_flow:install:migrations
rails db:migrate
```

**Issue:** Connection errors
- Check database.yml configuration
- Ensure database server is running

### Redcord Redis Backend

**Issue:** Connection refused
```bash
# Solution: Start Redis server
redis-server
```

**Issue:** Gem not found
```bash
# Solution: Add to Gemfile and bundle
gem 'redis'
gem 'redcord'
bundle install
```

### Redcord Redis Emulator Backend

**Issue:** Gem not found
```bash
# Solution: Add to Gemfile and bundle
gem 'redis-emulator'
gem 'redcord'
bundle install
```

**Issue:** Cache not configured
- Ensure Rails.cache is properly configured in config/cache.yml
- For production, use Solid Cache

## Example Configurations

### Development with Redis Emulator
```ruby
# config/environments/development.rb
config.cache_store = :solid_cache_store

# config/initializers/active_data_flow.rb
ActiveDataFlow.configure do |config|
  config.storage_backend = :redcord_redis_emulator
end
```

### Production with Redis
```ruby
# config/initializers/active_data_flow.rb
ActiveDataFlow.configure do |config|
  config.storage_backend = :redcord_redis
  config.redis_config = {
    url: ENV['REDIS_URL']
  }
end
```

### Production with ActiveRecord
```ruby
# config/initializers/active_data_flow.rb
ActiveDataFlow.configure do |config|
  config.storage_backend = :active_record
end
```
