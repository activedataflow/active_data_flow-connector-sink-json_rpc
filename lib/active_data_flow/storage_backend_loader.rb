# frozen_string_literal: true

require_relative "storage_backend/loader"

module ActiveDataFlow
  # Backward-compatible wrapper for StorageBackend::Loader.
  # Delegates all calls to the new modular loader structure.
  class StorageBackendLoader
    class << self
      def load!
        StorageBackend::Loader.load!
      end

      def setup_autoload_paths(engine)
        StorageBackend::Loader.setup_autoload_paths(engine)
      end

      def validate_dependencies
        StorageBackend::Loader.validate_dependencies
      end

      # Backward-compatible delegation methods
      def initialize_redis_connection
        StorageBackend::RedcordLoader.initialize_redis_connection(
          ActiveDataFlow.configuration.redis_config
        )
      end

      def initialize_redis_emulator
        StorageBackend::RedcordLoader.initialize_redis_emulator
      end

      def log_configuration
        logger = defined?(Rails) ? Rails.logger : Logger.new($stdout)
        config = ActiveDataFlow.configuration

        case config.storage_backend
        when :active_record
          StorageBackend::ActiveRecordLoader.log_configuration(logger)
        when :redcord_redis, :redcord_redis_emulator
          StorageBackend::RedcordLoader.log_configuration(
            logger,
            backend: config.storage_backend,
            redis_config: config.redis_config
          )
        end
      end
    end
  end
end
