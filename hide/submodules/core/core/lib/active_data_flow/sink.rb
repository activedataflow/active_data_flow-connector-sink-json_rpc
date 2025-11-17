# frozen_string_literal: true

module ActiveDataFlow
  # Base class for all data sinks
  class Sink
    # Class method to define required configuration attributes
    # Subclasses should override this to specify their own needs
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

    # Abstract method to write a single message
    # Must be implemented by subclasses
    # @param message [ActiveDataFlow::Message] the message to write
    def write(message)
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
