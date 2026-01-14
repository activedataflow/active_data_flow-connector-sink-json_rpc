# frozen_string_literal: true

module ActiveDataFlow
  class Configuration
    include ActiveDataFlow::Result

    attr_accessor :auto_load_data_flows, :log_level, :data_flows_path, :storage_backend, :redis_config

    SUPPORTED_BACKENDS = [:active_record, :redcord_redis, :redcord_redis_emulator].freeze

    def initialize
      @auto_load_data_flows = true
      @log_level = :info
      @data_flows_path = "app/data_flows"
      @storage_backend = :active_record
      @redis_config = {}
    end

    # Validates the configured storage backend.
    #
    # @return [Dry::Monads::Result] Success(backend) or Failure[:configuration_error, {...}]
    def validate_storage_backend
      if SUPPORTED_BACKENDS.include?(storage_backend)
        Success(storage_backend)
      else
        Failure[:configuration_error, {
          message: "Unsupported storage backend: #{storage_backend}. " \
                   "Supported backends: #{SUPPORTED_BACKENDS.join(', ')}",
          supported: SUPPORTED_BACKENDS,
          provided: storage_backend
        }]
      end
    end

    def active_record?
      storage_backend == :active_record
    end

    def redcord?
      redcord_redis? || redcord_redis_emulator?
    end

    def redcord_redis?
      storage_backend == :redcord_redis
    end

    def redcord_redis_emulator?
      storage_backend == :redcord_redis_emulator
    end
  end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
