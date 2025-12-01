# frozen_string_literal: true

module ActiveDataFlow
  module Connector
    module Source
      class Base
        # Base class for all source connectors
        
        attr_reader :options
        
        def initialize(**options)
          @options = options
        end
        
        # Iterate over records from the source
        def each
          raise NotImplementedError, "#{self.class} must implement #each"
        end
        
        # Close the source and release resources
        def close
          # Override in subclasses if needed
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
end
