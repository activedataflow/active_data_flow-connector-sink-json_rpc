# frozen_string_literal: true

require "active_data_flow/version"
require "active_data_flow/errors"
require "active_data_flow/result"
require "active_data_flow/configuration_base"
require "active_data_flow/configuration"
require "active_data_flow/storage_backend_loader"
require "active_data_flow/engine"
require "active_data_flow/railtie" if defined?(Rails::Railtie)

# Define namespaces (previously in empty module files)
module ActiveDataFlow
  module Connector
    module Source; end
    module Sink; end
  end
  module Runtime; end
  module Message; end
end

# Load base classes
require "active_data_flow/runtime/base"
require "active_data_flow/runtime/flow_executor"
require "active_data_flow/runtime/flow_reschedule"
require "active_data_flow/runtime/module_loader"
require "active_data_flow/message/untyped"
require "active_data_flow/message/typed"
require "active_data_flow/connector/source/base"
require "active_data_flow/connector/sink/base"
require "active_data_flow/connector/sink/buffer"
require "active_data_flow/connector/sink/collision"

# Load concerns and scheduler (only in Rails context)
require "active_data_flow/concerns" if defined?(Rails)
require "active_data_flow/scheduler" if defined?(Rails)
require "active_data_flow/data_flows_folder" if defined?(Rails)

