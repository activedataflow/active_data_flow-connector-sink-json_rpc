# frozen_string_literal: true

require_relative "active_record_loader"
require_relative "redcord_loader"

module ActiveDataFlow
  module StorageBackend
    # Main orchestrator for loading storage backends.
    # Delegates to backend-specific loaders.
    class Loader
      class << self
        include ActiveDataFlow::Result

        # Loads and initializes the configured storage backend.
        #
        # @return [Dry::Monads::Result] Success(:loaded) or Failure with error details
        def load!
          config = ActiveDataFlow.configuration
          yield config.validate_storage_backend

          yield load_backend(config)
          log_configuration(config)

          Success(:loaded)
        end

        # Configures autoload paths based on the storage backend.
        #
        # @param engine [Rails::Engine] The engine to configure
        def setup_autoload_paths(engine)
          config = ActiveDataFlow.configuration

          case config.storage_backend
          when :active_record
            ActiveRecordLoader.setup_autoload_paths(engine)
          when :redcord_redis, :redcord_redis_emulator
            RedcordLoader.setup_autoload_paths(engine)
          end
        end

        # Validates all dependencies for the current backend.
        #
        # @return [Dry::Monads::Result] Success(:valid) or Failure with error details
        def validate_dependencies
          config = ActiveDataFlow.configuration

          case config.storage_backend
          when :active_record
            ActiveRecordLoader.validate_dependencies
          when :redcord_redis
            RedcordLoader.validate_dependencies
          when :redcord_redis_emulator
            RedcordLoader.validate_emulator_dependencies
          end
        end

        private

        # Loads the appropriate backend based on configuration.
        #
        # @param config [Configuration] The configuration object
        # @return [Dry::Monads::Result]
        def load_backend(config)
          case config.storage_backend
          when :active_record
            ActiveRecordLoader.load!
          when :redcord_redis
            yield RedcordLoader.load!
            RedcordLoader.initialize_redis_connection(config.redis_config)
          when :redcord_redis_emulator
            yield RedcordLoader.load_with_emulator!
            RedcordLoader.initialize_redis_emulator
          end
        end

        # Logs configuration for the current backend.
        #
        # @param config [Configuration]
        def log_configuration(config)
          logger = defined?(Rails) ? Rails.logger : Logger.new($stdout)

          case config.storage_backend
          when :active_record
            ActiveRecordLoader.log_configuration(logger)
          when :redcord_redis, :redcord_redis_emulator
            RedcordLoader.log_configuration(
              logger,
              backend: config.storage_backend,
              redis_config: config.redis_config
            )
          end
        end
      end
    end
  end
end
