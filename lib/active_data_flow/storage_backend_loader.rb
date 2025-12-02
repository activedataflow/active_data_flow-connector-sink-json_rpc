# frozen_string_literal: true

module ActiveDataFlow
  class StorageBackendLoader
    class << self
      def load!
        config = ActiveDataFlow.configuration
        config.validate_storage_backend!

        case config.storage_backend
        when :active_record
          load_active_record_backend
        when :redcord_redis
          load_redcord_backend
          initialize_redis_connection
        when :redcord_redis_emulator
          load_redcord_backend
          initialize_redis_emulator
        end

        log_configuration
      end

      def setup_autoload_paths(engine)
        config = ActiveDataFlow.configuration

        case config.storage_backend
        when :active_record
          # ActiveRecord models are in app/models/active_data_flow/active_record/
          engine.config.autoload_paths << engine.root.join("app/models/active_data_flow/active_record")
          engine.config.eager_load_paths << engine.root.join("app/models/active_data_flow/active_record")
        when :redcord_redis, :redcord_redis_emulator
          # Redcord models are in app/models/active_data_flow/redcord/
          engine.config.autoload_paths << engine.root.join("app/models/active_data_flow/redcord")
          engine.config.eager_load_paths << engine.root.join("app/models/active_data_flow/redcord")
        end
      end

      def validate_dependencies!
        config = ActiveDataFlow.configuration

        case config.storage_backend
        when :active_record
          validate_active_record_dependencies!
        when :redcord_redis
          validate_redcord_dependencies!
        when :redcord_redis_emulator
          validate_redis_emulator_dependencies!
        end
      end

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
      rescue Redis::CannotConnectError => e
        raise ActiveDataFlow::ConnectionError,
              "Failed to connect to Redis: #{e.message}. " \
              "Ensure Redis is running and accessible."
      rescue StandardError => e
        raise ActiveDataFlow::ConnectionError,
              "Failed to connect to Redis: #{e.message}"
      end

      def initialize_redis_emulator
        redis_emulator = Redis::Emulator.new(
          backend: Rails.cache
        )

        Redcord.configure do |c|
          c.redis = redis_emulator
        end

        # No connectivity check needed - uses Rails.cache
      end

      private

      def load_active_record_backend
        validate_active_record_dependencies!
        # ActiveRecord models will be loaded automatically via Rails autoloading
      end

      def load_redcord_backend
        validate_redcord_dependencies!
        # Redcord models will be loaded automatically via Rails autoloading
      end

      def validate_active_record_dependencies!
        # ActiveRecord is part of Rails, so no additional validation needed
        true
      end

      def validate_redcord_dependencies!
        require "redcord"
      rescue LoadError
        raise ActiveDataFlow::DependencyError,
              "The 'redcord' gem is required for :redcord_redis backend. " \
              "Add 'gem \"redcord\"' to your Gemfile and run 'bundle install'."
      end

      def validate_redis_emulator_dependencies!
        validate_redcord_dependencies!

        require "redis/emulator"
      rescue LoadError
        raise ActiveDataFlow::DependencyError,
              "The 'redis-emulator' gem is required for :redcord_redis_emulator backend. " \
              "Add 'gem \"redis-emulator\"' to your Gemfile and run 'bundle install'."
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
    end
  end
end
