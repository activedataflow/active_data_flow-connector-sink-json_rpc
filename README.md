# ActiveDataFlow

A modular stream processing framework for Ruby inspired by Apache Flink. Provides a plugin-based architecture where a core gem defines abstract interfaces and separate gems provide concrete implementations for different runtimes and connectors.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_data_flow'
```

And then execute:

```bash
bundle install
```

**Note:** Generators are only available when the gem is installed in a Rails application. Run `rails generate --help | grep active_data_flow` to see available generators.

## Setup

Run the install generator:

```bash
rails generate active_data_flow:install
```

This will:
- Copy migrations to your application
- Mount the engine in your routes
- Create the `app/data_flows` directory
- Display setup instructions

Run the migrations:

```bash
rails db:migrate
```

### Optional: Ignore Data Flow Files

If you don't want to track data flow files in git, add to your `.gitignore`:

```
# Ignore data flow files (keep directory structure)
/app/data_flows/*.rb
!/app/data_flows/.keep
```

This is useful if data flows are environment-specific or generated dynamically.

## Configuration

The install generator creates `config/initializers/active_data_flow.rb` where you can customize behavior:

```ruby
ActiveDataFlow.configure do |config|
  # Storage backend (default: :active_record)
  # Options: :active_record, :redcord_redis, :redcord_redis_emulator
  config.storage_backend = :active_record

  # For Redcord backends, configure Redis connection
  # config.redis_config = { url: ENV['REDIS_URL'] }

  # Enable/disable automatic loading of data flows
  config.auto_load_data_flows = true

  # Set log level for data flow loading
  config.log_level = :info  # :debug, :info, :warn, :error

  # Set the path where data flows are located
  config.data_flows_path = "app/data_flows"
end
```

### Storage Backends

ActiveDataFlow supports multiple storage backends:

- **ActiveRecord** (default): Uses your Rails database
- **Redcord Redis**: Uses Redis via Redcord gem (requires `gem 'redcord', '~> 0.2.2'`)
- **Redcord Redis Emulator**: Uses Rails cache (no separate Redis needed)

See `docs/storage_backends.md` for detailed configuration and performance comparisons.

**Important:** Data flows are automatically loaded and registered by the engine AFTER Rails initialization completes and ActiveRecord is available. This ensures all dependencies (models, gems, etc.) are loaded before data flows are registered.

## Usage

The engine provides a web interface for managing data flows. Access it at:

```
http://localhost:3000/active_data_flow
```

### Mounting the Engine

The install generator automatically mounts the engine, but you can also mount it manually in `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  mount ActiveDataFlow::Engine => "/active_data_flow"
end
```

### Organizing Data Flows

Data flows are automatically loaded from `app/data_flows/`. Generate a new data flow:

```bash
rails generate active_data_flow:data_flow user_sync
```

This creates `app/data_flows/user_sync_flow.rb` where you can define your data flow.

### Creating Data Flows

Data flows are automatically registered when the application starts. Define a class with a `register` method:

```ruby

class SourceDataStage < FunctionalTaskSupervisor::Stage
  def perform
    source = ActiveDataFlow::Connector::Source::ActiveRecordSource.new(
      model_class: User,
      scope_name: :active,  # Calls User.active
      batch_size: 100 
    )
  end
end

class ProcessDataStage < FunctionalTaskSupervisor::Stage
  def perform
    sink = ActiveDataFlow::Connector::Sink::ActiveRecordSink.new(
      model_class: UserBackup,
      batch_size: 100
    )
  end
end

class SinkDataStage < FunctionalTaskSupervisor::Stage
  def perform
    sink = ActiveDataFlow::Connector::Sink::ActiveRecordSink.new(
      model_class: UserBackup,
      batch_size: 100
    )
  end
end

# Create task
task = SourceDataStage::Task.new
task.add_stage(ProcessDataStage.new)
task.add_stage(SinkDataStage.new)

runtime = ActiveDataFlow::Runtime::Heartbeat.new(
  interval: 60
)

# Create the data flow with instances
ActiveDataFlow::DataFlow.create_task(
  task: task,
  runtime: runtime
)
```

**Note:** For data flows that need to be persisted and reloaded, use the `model_class` + `scope_name` approach. Direct scopes work for immediate execution but cannot be fully serialized.

## Architecture

ActiveDataFlow follows a plugin-based architecture:

- **Core gem** (`active_data_flow`): Provides Rails engine and abstract interfaces
- **Connector gems**: Implement data sources and sinks
  - `active_data_flow-connector-source-active_record`
  - `active_data_flow-connector-sink-active_record`
- **Runtime gems**: Implement execution environments
  - `active_data_flow-runtime-heartbeat`

## Development

After checking out the repo, run:

```bash
bundle install
```

To run tests:

```bash
bundle exec rspec
```

## License

The gem is available as open source under the terms of the MIT License.
