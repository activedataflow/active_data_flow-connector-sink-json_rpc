# frozen_string_literal: true

module ActiveDataFlow
  # Registry for runtime adapters that provides a unified interface
  # for selecting and instantiating different runtime implementations.
  #
  # Supported runtimes:
  # - :active_job - Uses Rails ActiveJob with SolidQueue (recommended)
  # - :heartbeat - Legacy polling-based scheduler (deprecated)
  # - :redcord - Event-driven runtime using Redis (deprecated)
  #
  # @example Get the default runtime
  #   runtime = ActiveDataFlow::RuntimeRegistry.default_runtime
  #   runtime.schedule(my_flow)
  #
  # @example Get a specific runtime
  #   runtime = ActiveDataFlow::RuntimeRegistry.get(:active_job)
  #
  module RuntimeRegistry
    ADAPTERS = {
      active_job: "ActiveDataFlow::Runtime::ActiveJob",
      heartbeat: "ActiveDataFlow::Runtime::Heartbeat",
      redcord: "ActiveDataFlow::Runtime::Redcord"
    }.freeze

    DEPRECATED_ADAPTERS = %i[heartbeat redcord].freeze

    DEPRECATION_MESSAGES = {
      heartbeat: "The Heartbeat runtime is deprecated and will be removed in version 2.0. " \
                 "Please migrate to the ActiveJob runtime using: " \
                 "rails generate active_data_flow:migrate_to_activejob",
      redcord: "The Redcord runtime is deprecated and will be removed in version 2.0. " \
               "Please migrate to the ActiveJob runtime using: " \
               "rails generate active_data_flow:migrate_to_activejob"
    }.freeze

    class << self
      # Get the default runtime based on configuration
      #
      # @param options [Hash] Runtime options to pass to the constructor
      # @return [ActiveDataFlow::Runtime::Base] The runtime instance
      def default_runtime(**options)
        adapter = ActiveDataFlow.configuration.runtime_adapter
        get(adapter, **options)
      end

      # Get a specific runtime adapter
      #
      # @param adapter [Symbol] The adapter name (:active_job, :heartbeat, :redcord)
      # @param options [Hash] Runtime options to pass to the constructor
      # @return [ActiveDataFlow::Runtime::Base] The runtime instance
      def get(adapter, **options)
        validate_adapter!(adapter)
        emit_deprecation_warning(adapter)

        class_name = ADAPTERS[adapter]
        klass = class_name.constantize

        if options.any?
          klass.new(**options)
        else
          klass.new
        end
      rescue NameError => e
        raise ArgumentError, "Runtime adapter '#{adapter}' is not available: #{e.message}. " \
                             "Make sure the required files are loaded."
      end

      # Check if an adapter is available
      #
      # @param adapter [Symbol] The adapter name
      # @return [Boolean]
      def available?(adapter)
        return false unless ADAPTERS.key?(adapter)

        ADAPTERS[adapter].constantize
        true
      rescue NameError
        false
      end

      # List all registered adapters
      #
      # @return [Array<Symbol>]
      def adapters
        ADAPTERS.keys
      end

      # List available (loadable) adapters
      #
      # @return [Array<Symbol>]
      def available_adapters
        adapters.select { |a| available?(a) }
      end

      # Check if an adapter is deprecated
      #
      # @param adapter [Symbol] The adapter name
      # @return [Boolean]
      def deprecated?(adapter)
        DEPRECATED_ADAPTERS.include?(adapter)
      end

      # Get the recommended adapter
      #
      # @return [Symbol]
      def recommended
        :active_job
      end

      # Build runtime configuration for a flow
      #
      # @param adapter [Symbol] The adapter name
      # @param options [Hash] Runtime options
      # @return [Hash] Configuration hash to store in DataFlow.runtime
      def build_config(adapter, **options)
        validate_adapter!(adapter)

        {
          "class_name" => ADAPTERS[adapter],
          "adapter" => adapter.to_s
        }.merge(options.transform_keys(&:to_s))
      end

      # Parse runtime configuration from a flow
      #
      # @param runtime_config [Hash, nil] The stored runtime configuration
      # @return [Symbol, nil] The adapter name
      def parse_adapter(runtime_config)
        return nil unless runtime_config.is_a?(Hash)

        adapter_name = runtime_config["adapter"]
        return adapter_name.to_sym if adapter_name

        # Fallback: try to determine from class_name
        class_name = runtime_config["class_name"]
        return nil unless class_name

        ADAPTERS.find { |_, v| v == class_name }&.first
      end

      # Migrate a flow's runtime configuration from legacy to ActiveJob
      #
      # @param flow [DataFlow] The flow to migrate
      # @return [Hash] New runtime configuration
      def migrate_to_active_job(flow)
        old_runtime = flow.parsed_runtime || {}

        new_config = {
          "class_name" => ADAPTERS[:active_job],
          "adapter" => "active_job"
        }

        # Preserve compatible options
        %w[queue priority].each do |key|
          new_config[key] = old_runtime[key] if old_runtime[key]
        end

        # Convert interval to ActiveJob format
        if old_runtime["interval"] || flow.respond_to?(:interval_seconds)
          interval = old_runtime["interval"] || flow.interval_seconds
          new_config["interval"] = interval if interval.to_i.positive?
        end

        new_config
      end

      private

      def validate_adapter!(adapter)
        return if ADAPTERS.key?(adapter)

        raise ArgumentError, "Unknown runtime adapter: #{adapter}. " \
                             "Available adapters: #{ADAPTERS.keys.join(', ')}"
      end

      def emit_deprecation_warning(adapter)
        return unless deprecated?(adapter)

        message = DEPRECATION_MESSAGES[adapter]
        if defined?(ActiveSupport::Deprecation)
          ActiveSupport::Deprecation.warn(message)
        else
          warn "[DEPRECATION] #{message}"
        end
      end
    end
  end
end
