# frozen_string_literal: true

module ActiveDataFlow
  module StorageBackend
    # Loader for Redcord storage backends (Redis and Redis Emulator).
    class RedcordLoader
      class << self
        include ActiveDataFlow::Result

        # Loads Redcord backend with Redis connection.
        #
        # @return [Dry::Monads::Result] Success(:redcord)
        def load!
          yield validate_dependencies
          Success(:redcord)
        end

        # Loads Redcord backend with Redis Emulator.
        #
        # @return [Dry::Monads::Result] Success(:redcord)
        def load_with_emulator!
          yield validate_emulator_dependencies
          Success(:redcord)
        end

        # Validates Redcord gem is available.
        #
        # @return [Dry::Monads::Result] Success(:valid) or Failure[:dependency_error, {...}]
        def validate_dependencies
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

        # Validates Redis emulator dependencies.
        #
        # @return [Dry::Monads::Result] Success(:valid) or Failure[:dependency_error, {...}]
        def validate_emulator_dependencies
          result = validate_dependencies
          return result if result.failure?

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

        # Initializes connection to Redis server.
        #
        # @param config [Hash] Redis configuration
        # @return [Dry::Monads::Result] Success(redis_client) or Failure[:connection_error, {...}]
        def initialize_redis_connection(config)
          redis_client = Redis.new(
            url: config[:url] || "redis://localhost:6379/0",
            host: config[:host],
            port: config[:port],
            db: config[:db]
          )

          Redcord.configure do |c|
            c.redis = redis_client
          end

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

          Success(redis_emulator)
        end

        # Configures autoload paths for Redcord models.
        #
        # @param engine [Rails::Engine] The engine to configure
        def setup_autoload_paths(engine)
          path = engine.root.join("app/models/active_data_flow/redcord")
          engine.config.autoload_paths += [path] unless engine.config.autoload_paths.include?(path)
          engine.config.eager_load_paths += [path] unless engine.config.eager_load_paths.include?(path)
        end

        # Logs backend configuration.
        #
        # @param logger [Logger]
        # @param backend [Symbol] The backend type
        # @param redis_config [Hash] Redis configuration (optional)
        def log_configuration(logger, backend:, redis_config: nil)
          logger.info "[ActiveDataFlow] Storage backend: #{backend}"

          if backend == :redcord_redis
            logger.info "[ActiveDataFlow] Redis config: #{redis_config.inspect}"
          else
            logger.info "[ActiveDataFlow] Using Redis Emulator with Rails.cache"
          end
        end
      end
    end
  end
end
