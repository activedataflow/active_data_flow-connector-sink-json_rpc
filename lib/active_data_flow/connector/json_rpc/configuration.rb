# frozen_string_literal: true

module ActiveDataFlow
  module Connector
    module JsonRpc
      # Configuration for JSON-RPC connector
      class Configuration
        attr_accessor :default_host, :default_port, :timeout

        def initialize
          @default_host = '0.0.0.0'
          @default_port = 8999
          @timeout = 30
        end
      end
    end
  end
end
