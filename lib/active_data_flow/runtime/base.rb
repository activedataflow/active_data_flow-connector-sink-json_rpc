# frozen_string_literal: true

module ActiveDataFlow
  module Runtime
    class Base
      # Base class for all runtime implementations
      
      attr_reader :options, :batch_size, :enabled
      
      def initialize(batch_size: 100, enabled: true, **options)
        @batch_size = batch_size
        @enabled = enabled
        @options = options.merge(batch_size: batch_size, enabled: enabled)
      end
      
      # Execute a data flow
      def execute(data_flow)
        raise NotImplementedError, "#{self.class} must implement #execute"
      end
      
      # Transform a message - override in subclasses to implement custom transformation logic
      def transform(message)
        # Default implementation: pass through unchanged
        message
      end
      
      # Check if runtime is enabled
      def enabled?
        @enabled
      end
      
      # Serialize to JSON
      def as_json(*_args)
        @options.merge('class_name' => self.class.name)
      end
      
      # Deserialize from JSON
      def self.from_json(data)
        data = data.symbolize_keys
        data.delete(:class_name) # Remove class_name as it's not a constructor parameter
        new(**data)
      end
    end
  end
end
