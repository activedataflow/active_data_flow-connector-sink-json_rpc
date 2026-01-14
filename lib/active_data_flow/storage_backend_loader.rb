# frozen_string_literal: true

module ActiveDataFlow
  class StorageBackendLoader
    class << self
      include ActiveDataFlow::Result

      # Loads and initializes the configured storage backend.
      #
      # @return [Dry::Monads::Result] Success(:loaded) or Failure with error details
      def load!
        config = ActiveDataFlow.configuration
        result = yield config.validate_storage_backend

        case config.storage_backend
        when :active_record
          yield load_active_record_backend
        when :redcord_redis
          yield load_redcord_backend
          yield initialize_redis_connection
        when :redcord_redis_emulator
          yield load_redcord_backend
          yield initialize_redis_emulator
        end

        log_configuration
        Success(:loaded)
      end

      def setup_autoload_paths(engine)
        config = ActiveDataFlow.configuration

        case config.storage_backend
        when :active_record
          # ActiveRecord models are in app/models/active_data_flow/active_record/
          path = engine.root.join("app/models/active_data_flow/active_record")
          engine.config.autoload_paths += [path] unless engine.config.autoload_paths.include?(path)
          engine.config.eager_load_paths += [path] unless engine.config.eager_load_paths.include?(path)
        when :redcord_redis, :redcord_redis_emulator
          # Redcord models are in app/models/active_data_flow/redcord/
          path = engine.root.join("app/models/active_data_flow/redcord")
          engine.config.autoload_paths += [path] unless engine.config.autoload_paths.include?(path)
          engine.config.eager_load_paths += [path] unless engine.config.eager_load_paths.include?(path)
        end
      end

      # Validates all dependencies for the current backend.
      #
      # @return [Dry::Monads::Result] Success(:valid) or Failure with error details
      def validate_dependencies
        config = ActiveDataFlow.configuration

        case config.storage_backend
        when :active_record
          validate_active_record_dependencies
        when :redcord_redis
          validate_redcord_dependencies
        when :redcord_redis_emulator
          validate_redis_emulator_dependencies
        end
      end

      # Initializes connection to Redis server.
      #
      # @return [Dry::Monads::Result] Success(redis_client) or Failure[:connection_error, {...}]
      def initialize_redis_connection
        config = ActiveDataFlow.configuration.redis_config

        redis_client = Redis.new(
          url: config[:url] || "redis://localhost:6379/0",
          host: config[:host],
          port: config[:port],
          db: config[:db]
        )

        Redcord.configure do |c|
          c.redis = redis_client
        end

        # Validate connection
        redis_client.ping
        Success(redis_client)
      rescue Redis::CannotConnectError => e
        Failure[:connection_error, {
          message: "Failed to connect to Redis: #{e.message}. " \
                   "Ensure Redis is running and accessible.",
          config: config
        }]
      rescue StandardError => e
        Failure[:connection_error, {
          message: "Failed to connect to Redis: #{e.message}",
          exception_class: e.class.name,
          config: config
        }]
      end

      # Initializes Redis emulator using Rails.cache.
      #
      # @return [Dry::Monads::Result] Success(redis_emulator)
      def initialize_redis_emulator
        redis_emulator = Redis::Emulator.new(
          backend: Rails.cache
        )

        Redcord.configure do |c|
          c.redis = redis_emulator
        end

        # No connectivity check needed - uses Rails.cache
        Success(redis_emulator)
      end

      def log_configuration
        config = ActiveDataFlow.configuration
        logger = defined?(Rails) ? Rails.logger : Logger.new($stdout)

        logger.info "[ActiveDataFlow] Storage backend: #{config.storage_backend}"

        if config.redcord_redis?
          logger.info "[ActiveDataFlow] Redis config: #{config.redis_config.inspect}"
        elsif config.redcord_redis_emulator?
          logger.info "[ActiveDataFlow] Using Redis Emulator with Rails.cache"
        end
      end

      private

      # Loads ActiveRecord backend.
      #
      # @return [Dry::Monads::Result] Success(:active_record)
      def load_active_record_backend
        result = yield validate_active_record_dependencies
        # ActiveRecord models will be loaded automatically via Rails autoloading
        Success(:active_record)
      end

      # Loads Redcord backend.
      #
      # @return [Dry::Monads::Result] Success(:redcord) or Failure
      def load_redcord_backend
        result = yield validate_redcord_dependencies
        # Redcord models will be loaded automatically via Rails autoloading
        Success(:redcord)
      end

      # Validates ActiveRecord dependencies.
      #
      # @return [Dry::Monads::Result] Success(:valid)
      def validate_active_record_dependencies
        # ActiveRecord is part of Rails, so no additional validation needed
        Success(:valid)
      end

      # Validates Redcord gem is available.
      #
      # @return [Dry::Monads::Result] Success(:valid) or Failure[:dependency_error, {...}]
      def validate_redcord_dependencies
        require "redcord"
        Success(:valid)
      rescue LoadError
        Failure[:dependency_error, {
          message: "The 'redcord' gem is required for :redcord_redis backend. " \
                   "Add 'gem \"redcord\"' to your Gemfile and run 'bundle install'.",
          gem: "redcord",
          backend: :redcord_redis
        }]
      end

      # Validates Redis emulator gem is available.
      #
      # @return [Dry::Monads::Result] Success(:valid) or Failure[:dependency_error, {...}]
      def validate_redis_emulator_dependencies
        redcord_result = validate_redcord_dependencies
        return redcord_result if redcord_result.failure?

        require "redis/emulator"
        Success(:valid)
      rescue LoadError
        Failure[:dependency_error, {
          message: "The 'redis-emulator' gem is required for :redcord_redis_emulator backend. " \
                   "Add 'gem \"redis-emulator\"' to your Gemfile and run 'bundle install'.",
          gem: "redis-emulator",
          backend: :redcord_redis_emulator
        }]
      end
    end
  end
end
