# frozen_string_literal: true

# Check for jimson dependency
begin
  require 'jimson'
rescue LoadError => e
  raise LoadError, <<~MSG
    active_data_flow/connector/json_rpc requires the 'jimson' gem.
    Add this to your Gemfile:
      gem 'jimson', '~> 0.10'

    Original error: #{e.message}
  MSG
end

require 'active_support'
require 'active_data_flow'

require_relative 'json_rpc/configuration'
require_relative 'json_rpc/server_handler'
require_relative 'json_rpc/client_wrapper'

module ActiveDataFlow
  module Connector
    module JsonRpc
      class Error < StandardError; end

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
