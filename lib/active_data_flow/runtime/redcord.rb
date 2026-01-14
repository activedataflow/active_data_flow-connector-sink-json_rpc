# frozen_string_literal: true

# Check for redcord dependency
begin
  require 'redcord'
rescue LoadError => e
  raise LoadError, <<~MSG
    active_data_flow/runtime/redcord requires the 'redcord' gem.
    Add this to your Gemfile:
      gem 'redcord', '~> 0.2.2'

    Original error: #{e.message}
  MSG
end

require 'active_record'
require 'active_support'
require 'active_data_flow'
require 'active_data_flow/runtime/base'
require 'active_data_flow/runtime/flow_executor'
require 'active_data_flow/runtime/flow_reschedule'
require 'active_data_flow/runtime/module_loader'
require 'active_data_flow/configuration_base'

require_relative 'redcord/configuration'
require_relative 'redcord/flow_executor'

module ActiveDataFlow
  module Runtime
    module Redcord
      extend ActiveDataFlow::ConfigurationBase

      class << self
        alias_method :config, :configuration
      end
    end
  end
end

# Load models and controllers via ModuleLoader
ActiveDataFlow::Runtime::ModuleLoader.load_backend_files(
  "redcord",
  models: %w[data_flow data_flow_run],
  controllers: %w[data_flows_controller]
)
