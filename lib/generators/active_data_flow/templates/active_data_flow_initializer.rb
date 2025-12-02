# ActiveDataFlow Configuration
ActiveDataFlow.configure do |config|
  # Storage Backend Configuration
  # Choose one of: :active_record, :redcord_redis, :redcord_redis_emulator
  # Default: :active_record
  config.storage_backend = :active_record

  # === ActiveRecord Backend (default) ===
  # Uses your Rails database (PostgreSQL, MySQL, SQLite, etc.)
  # Requires: Standard Rails setup with database.yml
  # Migrations: Run `rails active_data_flow:install:migrations` and `rails db:migrate`

  # === Redcord Redis Backend ===
  # Uses a standard Redis server for storage
  # Requires: gem 'redis' and gem 'redcord'
  # config.storage_backend = :redcord_redis
  # config.redis_config = {
  #   url: ENV['REDIS_URL'] || 'redis://localhost:6379/0'
  #   # OR specify individual options:
  #   # host: 'localhost',
  #   # port: 6379,
  #   # db: 0
  # }

  # === Redcord Redis Emulator Backend ===
  # Uses redis-emulator backed by Rails Solid Cache (no separate Redis server needed)
  # Requires: gem 'redis-emulator' and gem 'redcord'
  # config.storage_backend = :redcord_redis_emulator
  # Note: Uses Rails.cache as backing store (configure in config/cache.yml)

  # Other configuration options
  config.auto_load_data_flows = true
  config.log_level = :info
  config.data_flows_path = "app/data_flows"
end
