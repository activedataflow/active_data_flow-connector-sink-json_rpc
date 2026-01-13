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

require_relative 'redcord/configuration'
require_relative 'redcord/flow_executor'
require_relative 'redcord/flow_reschedule'

module ActiveDataFlow
  module Runtime
    module Redcord
      class << self
        attr_writer :configuration

        def configuration
          @configuration ||= Configuration.new
        end

        alias_method :config, :configuration

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
  require_relative '../../../app/models/active_data_flow/runtime/redcord/data_flow'
  require_relative '../../../app/models/active_data_flow/runtime/redcord/data_flow_run'
  require_relative '../../../app/controllers/active_data_flow/runtime/redcord/data_flows_controller'
end
