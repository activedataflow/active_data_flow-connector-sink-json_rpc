# frozen_string_literal: true

require 'active_record'
require 'active_support'
require 'active_data_flow'
require 'active_data_flow/runtime/base'
require 'active_data_flow/runtime/flow_executor'
require 'active_data_flow/runtime/flow_reschedule'
require 'active_data_flow/runtime/module_loader'
require 'active_data_flow/configuration_base'

require_relative 'heartbeat/configuration'
require_relative 'heartbeat/flow_run_executor'
require_relative 'heartbeat/schedule_flow_runs'
require_relative 'heartbeat/base'

module ActiveDataFlow
  module Runtime
    module Heartbeat
      extend ActiveDataFlow::ConfigurationBase
    end
  end
end

# Load models and controllers via ModuleLoader
ActiveDataFlow::Runtime::ModuleLoader.load_backend_files(
  "heartbeat",
  models: %w[data_flow data_flow_run],
  controllers: %w[data_flows_controller data_flow_runs_controller]
)
