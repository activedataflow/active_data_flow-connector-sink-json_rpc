# frozen_string_literal: true

require "active_data_flow/version"
require "active_data_flow/configuration"
require "active_data_flow/engine"
require "active_data_flow/railtie" if defined?(Rails::Railtie)

# Load base classes
require "active_data_flow/runtime/base"
require "active_data_flow/message"
require "active_data_flow/connector"
require "active_data_flow/connector/source/base"
require "active_data_flow/runtime"
require "active_data_flow/connector/sink/base"
require "active_data_flow/connector/sink/collision"

# Load concerns and scheduler (only in Rails context)
require "active_data_flow/concerns" if defined?(Rails)
require "active_data_flow/scheduler" if defined?(Rails)
require "active_data_flow/data_flows_folder" if defined?(Rails)

