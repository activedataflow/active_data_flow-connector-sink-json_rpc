# frozen_string_literal: true

module ActiveDataFlow
  # Registry for managing plugin implementations
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
          raise ConfigurationError, "Unknown source type: #{type}. Available: #{available_sources.join(', ')}"
        end
      end

      # Look up a sink class by type
      # @param type [Symbol] the sink type
      # @return [Class] the sink class
      def sink(type)
        sinks.fetch(type) do
          raise ConfigurationError, "Unknown sink type: #{type}. Available: #{available_sinks.join(', ')}"
        end
      end

      # Look up a runtime class by type
      # @param type [Symbol] the runtime type
      # @return [Class] the runtime class
      def runtime(type)
        runtimes.fetch(type) do
          raise ConfigurationError, "Unknown runtime type: #{type}. Available: #{available_runtimes.join(', ')}"
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

      # Register a subcomponent gem
      # @param name [String] the gem name
      # @param version [String] the gem version
      def register_subcomponent(name, version)
        subcomponents[name] = version
      end

      # List all registered subcomponents
      # @return [Hash] subcomponent names and versions
      def subcomponents
        @subcomponents ||= {}
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
