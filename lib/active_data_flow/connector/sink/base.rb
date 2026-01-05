# frozen_string_literal: true

module ActiveDataFlow
  module Connector
    module Sink
      class Base
        def initialize(**options)
          @options = options
        end

        def write(record)
          raise NotImplementedError, "Subclasses must implement #write"
        end

        def write_batch(records)
          raise NotImplementedError, "Subclasses must implement #write_batch"
        end

        def close
          # Override in subclasses if cleanup is needed
        end

        def to_json(*args)
          @options.to_json(*args)
        end

        protected

        attr_reader :options
      end
    end
  end
end
