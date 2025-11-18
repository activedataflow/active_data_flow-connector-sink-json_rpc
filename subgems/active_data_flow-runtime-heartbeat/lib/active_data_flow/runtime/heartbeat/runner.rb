# frozen_string_literal: true

require "active_data_flow"
require "rails"
require_relative "version"
require_relative "configuration"

module ActiveDataFlow
  module Runtime
    module Heartbeat
      class << self
        def config
          @config ||= Configuration.new
        end

        def configure
          yield config
        end
      end
    end
  end
end
