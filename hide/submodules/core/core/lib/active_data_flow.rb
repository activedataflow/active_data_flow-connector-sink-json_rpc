# frozen_string_literal: true

require_relative "active_data_flow/version"
require_relative "active_data_flow/errors"
require_relative "active_data_flow/configuration"
require_relative "active_data_flow/message"
require_relative "active_data_flow/logger"
require_relative "active_data_flow/source"
require_relative "active_data_flow/sink"
require_relative "active_data_flow/data_flow"
require_relative "active_data_flow/registry"

module ActiveDataFlow
  class << self
    # Convenience method to create a source from registry
    # @param type [Symbol] the source type
    # @param configuration [Hash] source configuration
    # @return [Source] a source instance
    def source(type, configuration = {})
      Registry.source(type).new(configuration)
    end

    # Convenience method to create a sink from registry
    # @param type [Symbol] the sink type
    # @param configuration [Hash] sink configuration
    # @return [Sink] a sink instance
    def sink(type, configuration = {})
      Registry.sink(type).new(configuration)
    end
  end
end
