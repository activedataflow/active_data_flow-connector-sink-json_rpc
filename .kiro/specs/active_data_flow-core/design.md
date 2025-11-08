# ActiveDataFlow Core - Design Document

## Overview

The `active_data_flow` core gem provides the foundational abstractions for a modular stream processing framework. It defines interfaces and base classes that enable pluggable runtimes and connectors while maintaining a consistent API across all implementations.

The design follows the **Strategy Pattern** for sources and sinks, the **Registry Pattern** for plugin management, and the **Template Method Pattern** for DataFlow orchestration.

## Architecture

### High-Level Structure

```
ActiveDataFlow (module)
├── Source (base class)
├── Sink (base class)
├── DataFlow (module)
├── Registry (singleton)
├── Configuration (class)
├── Logger (module)
├── Errors (module)
└── Version (constant)
```

### Design Principles

1. **Interface Segregation**: Each base class defines only the methods needed for its role
2. **Open/Closed**: Core is closed for modification, open for extension via plugins
3. **Dependency Inversion**: Core depends on abstractions, not concrete implementations
4. **Single Responsibility**: Each class has one clear purpose
5. **Plugin Architecture**: All concrete implementations live in separate gems

## Components and Interfaces

### 1. Source Base Class

The `Source` class provides the contract for all data sources.

```ruby
module ActiveDataFlow
  class Source
    # Class method to define required configuration attributes
    # @return [Hash] attribute definitions with types
    def self.configuration_attributes
      {}
    end

    # Initialize with configuration hash
    # @param configuration [Hash] source-specific settings
    def initialize(configuration)
      @configuration = Configuration.new(
        configuration,
        self.class.configuration_attributes
      )
    end

    # Abstract method to iterate over records
    # Must be implemented by subclasses
    # @yield [Object] each record from the source
    def each(&block)
      raise NotImplementedError, "#{self.class}#each must be implemented"
    end

    protected

    attr_reader :configuration
  end
end
```

**Key Design Decisions:**
- Uses `each` with block for iterator pattern (Ruby idiomatic)
- Configuration validation happens in initializer
- Protected `configuration` accessor for subclass access
- Class-level `configuration_attributes` for introspection

### 2. Sink Base Class

The `Sink` class provides the contract for all data destinations.

```ruby
module ActiveDataFlow
  class Sink
    # Class method to define required configuration attributes
    # @return [Hash] attribute definitions with types
    def self.configuration_attributes
      {}
    end

    # Initialize with configuration hash
    # @param configuration [Hash] sink-specific settings
    def initialize(configuration)
      @configuration = Configuration.new(
        configuration,
        self.class.configuration_attributes
      )
    end

    # Abstract method to write a single record
    # Must be implemented by subclasses
    # @param record [Object] the record to write
    def write(record)
      raise NotImplementedError, "#{self.class}#write must be implemented"
    end

    # Optional method for batch flushing
    # Subclasses can override if they buffer writes
    def flush
      # Default: no-op
    end

    # Optional method for cleanup
    # Subclasses can override for resource cleanup
    def close
      # Default: no-op
    end

    protected

    attr_reader :configuration
  end
end
```

**Key Design Decisions:**
- Single-record `write` method for simplicity
- Optional `flush` and `close` for resource management
- Same configuration pattern as Source
- Subclasses can add batching internally

### 3. DataFlow Module

The `DataFlow` module provides orchestration capabilities when included in a class.

```ruby
module ActiveDataFlow
  module DataFlow
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Define configuration attributes for this DataFlow
      # @return [Hash] attribute definitions
      def configuration_attributes
        {}
      end
    end

    # Initialize with configuration
    # @param configuration [Hash] flow-specific settings
    def initialize(configuration = {})
      @configuration = Configuration.new(
        configuration,
        self.class.configuration_attributes
      )
      @logger = Logger.for(self.class.name)
    end

    # Abstract method to execute the flow
    # Must be implemented by including class
    def run
      raise NotImplementedError, "#{self.class}#run must be implemented"
    end

    protected

    attr_reader :configuration, :logger
  end
end
```

**Key Design Decisions:**
- Module for mixin pattern (Ruby idiomatic)
- Automatic logger creation per DataFlow
- Configuration validation on initialization
- Template method pattern for `run`

### 4. Registry System

The `Registry` manages plugin registration and lookup.

```ruby
module ActiveDataFlow
  class Registry
    class << self
      # Register a source implementation
      # @param type [Symbol] the source type identifier
      # @param klass [Class] the source class
      def register_source(type, klass)
        validate_source_class!(klass)
        sources[type] = klass
      end

      # Register a sink implementation
      # @param type [Symbol] the sink type identifier
      # @param klass [Class] the sink class
      def register_sink(type, klass)
        validate_sink_class!(klass)
        sinks[type] = klass
      end

      # Register a runtime implementation
      # @param type [Symbol] the runtime type identifier
      # @param klass [Class] the runtime class
      def register_runtime(type, klass)
        runtimes[type] = klass
      end

      # Look up a source class by type
      # @param type [Symbol] the source type
      # @return [Class] the source class
      def source(type)
        sources.fetch(type) do
          raise ConfigurationError, "Unknown source type: #{type}"
        end
      end

      # Look up a sink class by type
      # @param type [Symbol] the sink type
      # @return [Class] the sink class
      def sink(type)
        sinks.fetch(type) do
          raise ConfigurationError, "Unknown sink type: #{type}"
        end
      end

      # Look up a runtime class by type
      # @param type [Symbol] the runtime type
      # @return [Class] the runtime class
      def runtime(type)
        runtimes.fetch(type) do
          raise ConfigurationError, "Unknown runtime type: #{type}"
        end
      end

      # List all registered sources
      # @return [Array<Symbol>] source type identifiers
      def available_sources
        sources.keys
      end

      # List all registered sinks
      # @return [Array<Symbol>] sink type identifiers
      def available_sinks
        sinks.keys
      end

      # List all registered runtimes
      # @return [Array<Symbol>] runtime type identifiers
      def available_runtimes
        runtimes.keys
      end

      private

      def sources
        @sources ||= {}
      end

      def sinks
        @sinks ||= {}
      end

      def runtimes
        @runtimes ||= {}
      end

      def validate_source_class!(klass)
        unless klass < Source
          raise ArgumentError, "Source class must inherit from ActiveDataFlow::Source"
        end
      end

      def validate_sink_class!(klass)
        unless klass < Sink
          raise ArgumentError, "Sink class must inherit from ActiveDataFlow::Sink"
        end
      end
    end
  end
end
```

**Key Design Decisions:**
- Singleton pattern using class methods
- Separate registries for sources, sinks, and runtimes
- Validation on registration
- Helpful error messages for missing plugins
- Introspection methods for available components

### 5. Configuration Class

The `Configuration` class validates and provides access to configuration values.

```ruby
module ActiveDataFlow
  class Configuration
    # Initialize with values and attribute definitions
    # @param values [Hash] the configuration values
    # @param attributes [Hash] attribute definitions with types
    def initialize(values, attributes = {})
      @values = values.symbolize_keys
      @attributes = attributes
      validate!
    end

    # Access configuration value
    # @param key [Symbol] the attribute key
    # @return [Object] the configuration value
    def [](key)
      @values[key]
    end

    # Check if attribute is present
    # @param key [Symbol] the attribute key
    # @return [Boolean] true if present
    def key?(key)
      @values.key?(key)
    end

    # Convert to hash
    # @return [Hash] the configuration as a hash
    def to_h
      @values.dup
    end

    private

    def validate!
      validate_required_attributes!
      validate_attribute_types!
    end

    def validate_required_attributes!
      @attributes.each do |key, definition|
        next if definition[:optional]
        unless @values.key?(key)
          raise ConfigurationError, "Missing required configuration: #{key}"
        end
      end
    end

    def validate_attribute_types!
      @attributes.each do |key, definition|
        next unless @values.key?(key)
        value = @values[key]
        expected_type = definition[:type]
        
        unless valid_type?(value, expected_type)
          raise ConfigurationError,
            "Invalid type for #{key}: expected #{expected_type}, got #{value.class}"
        end
      end
    end

    def valid_type?(value, expected_type)
      case expected_type
      when :string
        value.is_a?(String)
      when :integer
        value.is_a?(Integer)
      when :boolean
        value.is_a?(TrueClass) || value.is_a?(FalseClass)
      when :hash
        value.is_a?(Hash)
      when :array
        value.is_a?(Array)
      else
        true # Unknown types pass validation
      end
    end
  end
end
```

**Key Design Decisions:**
- Immutable after validation
- Type checking for common types
- Required vs optional attributes
- Hash-like access pattern
- Clear error messages

### 6. Error Handling

Custom exception classes for different error scenarios.

```ruby
module ActiveDataFlow
  # Base error class for all ActiveDataFlow errors
  class Error < StandardError; end

  # Configuration-related errors
  class ConfigurationError < Error; end

  # Source-related errors
  class SourceError < Error; end

  # Sink-related errors
  class SinkError < Error; end

  # Runtime-related errors
  class RuntimeError < Error; end

  # Version compatibility errors
  class VersionError < Error; end
end
```

**Key Design Decisions:**
- Hierarchy with base `Error` class
- Specific error types for different components
- Inherits from `StandardError` for proper rescue behavior

### 7. Logging Interface

The `Logger` module provides structured logging capabilities.

```ruby
module ActiveDataFlow
  module Logger
    class << self
      # Get a logger for a specific component
      # @param name [String] the component name
      # @return [LoggerInstance] a logger instance
      def for(name)
        LoggerInstance.new(name)
      end

      # Configure the logging backend
      # @param backend [Object] the logging backend (e.g., Rails.logger)
      def backend=(backend)
        @backend = backend
      end

      # Get the current logging backend
      # @return [Object] the logging backend
      def backend
        @backend ||= default_backend
      end

      private

      def default_backend
        if defined?(Rails)
          Rails.logger
        else
          require 'logger'
          ::Logger.new($stdout)
        end
      end
    end

    class LoggerInstance
      def initialize(name)
        @name = name
      end

      def debug(message = nil, **context, &block)
        log(:debug, message, context, &block)
      end

      def info(message = nil, **context, &block)
        log(:info, message, context, &block)
      end

      def warn(message = nil, **context, &block)
        log(:warn, message, context, &block)
      end

      def error(message = nil, **context, &block)
        log(:error, message, context, &block)
      end

      private

      def log(level, message, context, &block)
        message = block.call if block_given?
        formatted = format_message(message, context)
        Logger.backend.send(level, formatted)
      end

      def format_message(message, context)
        parts = ["[#{@name}]", message]
        unless context.empty?
          parts << context.map { |k, v| "#{k}=#{v}" }.join(' ')
        end
        parts.join(' ')
      end
    end
  end
end
```

**Key Design Decisions:**
- Pluggable backend (Rails.logger or stdlib Logger)
- Structured logging with key-value pairs
- Component-specific loggers
- Block support for lazy evaluation

### 8. Version Management

Version constant and compatibility checking.

```ruby
module ActiveDataFlow
  VERSION = "1.0.0"

  module Version
    class << self
      # Check if a plugin version is compatible
      # @param plugin_version [String] the plugin's required core version
      # @return [Boolean] true if compatible
      def compatible?(plugin_version)
        Gem::Dependency.new('', plugin_version).match?('', VERSION)
      end

      # Validate plugin compatibility, raise if incompatible
      # @param plugin_name [String] the plugin gem name
      # @param plugin_version [String] the plugin's required core version
      def validate!(plugin_name, plugin_version)
        unless compatible?(plugin_version)
          raise VersionError,
            "#{plugin_name} requires active_data_flow #{plugin_version}, " \
            "but #{VERSION} is loaded"
        end
      end
    end
  end
end
```

**Key Design Decisions:**
- Semantic versioning support via Gem::Dependency
- Explicit validation method for plugins
- Clear error messages with version information

## Data Models

### Configuration Schema

Configuration objects follow this structure:

```ruby
{
  type: :symbol,           # Required: identifies the implementation
  # ... implementation-specific attributes
}
```

Example source configuration:
```ruby
{
  type: :rafka,
  stream_name: "events",
  consumer_group: "processors",
  consumer_name: "worker-1"
}
```

Example sink configuration:
```ruby
{
  type: :active_record,
  model_name: "Event"
}
```

## Error Handling Strategy

### Error Propagation

1. **Configuration Errors**: Raised immediately during initialization
2. **Source Errors**: Wrapped and re-raised with context
3. **Sink Errors**: Wrapped and re-raised with context
4. **Runtime Errors**: Handled by runtime implementation

### Error Context

All errors include:
- Component name
- Operation being performed
- Original error message
- Stack trace

## Testing Strategy

### Unit Tests

Each component has isolated unit tests:
- `Source` base class behavior
- `Sink` base class behavior
- `DataFlow` module inclusion
- `Registry` registration and lookup
- `Configuration` validation
- Error class hierarchy
- Logger formatting

### Integration Tests

Test component interactions:
- Source/Sink with Configuration
- DataFlow with Logger
- Registry with validation
- Version compatibility checks

### Test Doubles

Provide test implementations:
- `TestSource` - Simple in-memory source
- `TestSink` - Collects records in array
- `TestDataFlow` - Minimal flow implementation

## Performance Considerations

1. **Lazy Loading**: Registry doesn't load classes until needed
2. **Minimal Overhead**: Base classes add minimal method call overhead
3. **No Global State**: Except Registry singleton
4. **Memory Efficient**: Configuration validated once, not on every access

## Security Considerations

1. **Input Validation**: All configuration validated before use
2. **Type Safety**: Configuration types checked
3. **No Code Execution**: No `eval` or dynamic code execution
4. **Plugin Validation**: Plugins must inherit from base classes

## Deployment Considerations

### Gem Structure

```
active_data_flow/
├── lib/
│   ├── active_data_flow.rb           # Main entry point
│   ├── active_data_flow/
│   │   ├── source.rb                 # Source base class
│   │   ├── sink.rb                   # Sink base class
│   │   ├── data_flow.rb              # DataFlow module
│   │   ├── registry.rb               # Registry singleton
│   │   ├── configuration.rb          # Configuration class
│   │   ├── logger.rb                 # Logger module
│   │   ├── errors.rb                 # Error classes
│   │   └── version.rb                # Version constant
│   └── active_data_flow/
│       └── test_helpers.rb           # Test doubles
├── spec/                              # RSpec tests
├── active_data_flow.gemspec
└── README.md
```

### Dependencies

Minimal dependencies:
- Ruby >= 2.7
- No runtime dependencies (pure Ruby)
- Development dependencies: rspec, rubocop

### Versioning

Follow semantic versioning:
- Major: Breaking API changes
- Minor: New features, backward compatible
- Patch: Bug fixes

## Future Enhancements

1. **Metrics**: Built-in metrics collection
2. **Tracing**: Distributed tracing support
3. **Schema Registry**: Optional schema validation
4. **Async Support**: Async/await patterns for I/O
5. **Backpressure**: Flow control mechanisms
