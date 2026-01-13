# frozen_string_literal: true

require 'active_record'
require 'active_support'
require 'active_data_flow'
require 'active_data_flow/runtime/base'

require_relative 'heartbeat/configuration'
require_relative 'heartbeat/flow_run_executor'
require_relative 'heartbeat/schedule_flow_runs'
require_relative 'heartbeat/flow_reschedule'
require_relative 'heartbeat/base'

module ActiveDataFlow
  module Runtime
    module Heartbeat
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
  end
end

# Load models and controllers when Rails is available
if defined?(Rails)
  require_relative '../../../app/models/active_data_flow/runtime/heartbeat/data_flow'
  require_relative '../../../app/models/active_data_flow/runtime/heartbeat/data_flow_run'
  require_relative '../../../app/controllers/active_data_flow/runtime/heartbeat/data_flows_controller'
  require_relative '../../../app/controllers/active_data_flow/runtime/heartbeat/data_flow_runs_controller'
end
