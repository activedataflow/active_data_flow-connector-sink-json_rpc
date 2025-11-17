# ActiveDataFlow Core

The core gem for the ActiveDataFlow modular stream processing framework. Provides abstract interfaces and base classes for building pluggable data processing pipelines.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_data_flow-core-core'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install active_data_flow-core-core
```

## Overview

ActiveDataFlow Core provides:

- **Source** - Base class for data sources
- **Sink** - Base class for data destinations
- **DataFlow** - Module for orchestrating data processing
- **Message** - Typed message abstractions (Unconstrained, CloudEvent, CloudEventLd)
- **Registry** - Plugin system for sources, sinks, and runtimes
- **Configuration** - Validation and type checking
- **Logger** - Structured logging interface
- **Version** - Compatibility checking for plugins

## Usage

### Creating a Custom Source

```ruby
class MySource < ActiveDataFlow::Source
  def self.configuration_attributes
    {
      url: { type: :string, optional: false },
      timeout: { type: :integer, optional: true }
    }
  end

  def each(&block)
    # Fetch data from your source
    data.each do |item|
      message = ActiveDataFlow::Message::Unconstrained.new(item)
      yield message
    end
  end
end

# Register your source
ActiveDataFlow::Registry.register_source(:my_source, MySource)
```

### Creating a Custom Sink

```ruby
class MySink < ActiveDataFlow::Sink
  def self.configuration_attributes
    {
      destination: { type: :string, optional: false }
    }
  end

  def write(message)
    # Write message to your destination
    puts "Writing: #{message.to_h}"
  end

  def flush
    # Optional: flush buffered writes
  end

  def close
    # Optional: cleanup resources
  end
end

# Register your sink
ActiveDataFlow::Registry.register_sink(:my_sink, MySink)
```

### Creating a DataFlow

```ruby
class MyDataFlow
  include ActiveDataFlow::DataFlow

  def self.configuration_attributes
    {
      source: { type: :hash, optional: false },
      sink: { type: :hash, optional: false }
    }
  end

  def run
    source = ActiveDataFlow.source(:my_source, configuration[:source])
    sink = ActiveDataFlow.sink(:my_sink, configuration[:sink])

    source.each do |message|
      transformed = transform(message)
      sink.write(transformed)
    end

    sink.flush
    sink.close
  end

  private

  def transform(message)
    # Transform your message
    data = message.to_h
    data[:processed_at] = Time.now
    ActiveDataFlow::Message::Unconstrained.new(data)
  end
end
```

### Running a DataFlow

```ruby
flow = MyDataFlow.new(
  source: { url: "https://api.example.com/data", timeout: 30 },
  sink: { destination: "/tmp/output.json" }
)

flow.run
```

## Message Types

ActiveDataFlow supports three message types:

### Unconstrained Messages

```ruby
message = ActiveDataFlow::Message::Unconstrained.new({ id: 1, name: "Test" })
message.data # => { id: 1, name: "Test" }
message.to_h # => { id: 1, name: "Test" }
```

### CloudEvents

```ruby
message = ActiveDataFlow::Message::CloudEvent.new(
  id: "123",
  source: "my-app",
  specversion: "1.0",
  type: "com.example.event",
  data: { key: "value" }
)
```

### CloudEventsLd (Linked Data)

```ruby
message = ActiveDataFlow::Message::CloudEventLd.new(
  id: "123",
  source: "my-app",
  specversion: "1.0",
  type: "com.example.event",
  "@context": "https://schema.org",
  data: { key: "value" }
)
```

## Registry

The Registry manages all registered components:

```ruby
# List available sources
ActiveDataFlow::Registry.available_sources # => [:my_source]

# List available sinks
ActiveDataFlow::Registry.available_sinks # => [:my_sink]

# Get a source class
source_class = ActiveDataFlow::Registry.source(:my_source)

# Create a source instance
source = ActiveDataFlow.source(:my_source, url: "https://api.example.com")
```

## Logging

ActiveDataFlow provides structured logging:

```ruby
class MyDataFlow
  include ActiveDataFlow::DataFlow

  def run
    logger.info "Starting flow", flow_id: 123
    logger.debug "Processing message", message_id: 456
    logger.error "Failed to process", error: "Connection timeout"
  end
end
```

Configure the logging backend:

```ruby
# Use Rails logger
ActiveDataFlow::Logger.backend = Rails.logger

# Use custom logger
ActiveDataFlow::Logger.backend = Logger.new($stdout)
```

## Testing

ActiveDataFlow provides test helpers:

```ruby
require 'active_data_flow/test_helpers'

RSpec.describe MyDataFlow do
  it "processes messages" do
    flow = MyDataFlow.new(
      source: { data: [{ id: 1 }, { id: 2 }] },
      sink: {}
    )

    sink = flow.run
    expect(sink.messages.size).to eq(2)
  end
end
```

## Plugin Development

To create a plugin gem:

1. Depend on `active_data_flow-core-core` in your gemspec:

```ruby
spec.add_dependency 'active_data_flow-core-core', '~> 0.0.1'
```

2. Register your components when the gem is loaded:

```ruby
# lib/my_plugin.rb
require 'active_data_flow'

module MyPlugin
  class MySource < ActiveDataFlow::Source
    # ...
  end
end

ActiveDataFlow::Registry.register_source(:my_plugin, MyPlugin::MySource)
ActiveDataFlow::Registry.register_subcomponent('my_plugin', '1.0.0')
```

3. Validate version compatibility:

```ruby
ActiveDataFlow::Version.validate!('my_plugin', '~> 1.0')
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/activedataflow/active_data_flow-core-core.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
