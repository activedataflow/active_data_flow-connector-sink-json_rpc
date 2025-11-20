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

## Setup

Run the install generator:

```bash
rails generate active_data_flow:install
```

This will:
- Copy migrations to your application
- Mount the engine in your routes
- Display setup instructions

Run the migrations:

```bash
rails db:migrate
```

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

### Creating Data Flows

Data flows can be created programmatically:

```ruby
ActiveDataFlow::DataFlow.create!(
  name: "user_sync",
  source_type: "ActiveDataFlow::Connector::Source::ActiveRecord",
  source_config: { model: "User" }.to_json,
  sink_type: "ActiveDataFlow::Connector::Sink::ActiveRecord",
  sink_config: { model: "UserBackup" }.to_json,
  runtime_type: "ActiveDataFlow::Runtime::Heartbeat"
)
```

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
