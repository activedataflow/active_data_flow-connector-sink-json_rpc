# frozen_string_literal: true

module ActiveDataflow
  module Connector
    module Source
      # Base class for data sources
      # Subclasses must implement the #each method to yield records
      class Base
        attr_reader :config

        def initialize(config = {})
          @config = config
          validate_config!
        end

        # Yields records from the source
        # Subclasses must implement this method
        def each
          raise NotImplementedError, "#{self.class} must implement #each method"
        end

        private

        # Override in subclasses to validate required configuration
        def validate_config!
          # Base implementation does nothing
        end

        # Helper method for subclasses to require config keys
        def require_config_keys(*keys)
          missing = keys - config.keys
          unless missing.empty?
            raise ArgumentError, "Missing required configuration keys: #{missing.join(', ')}"
          end
        end
      end
    end
  end
end
