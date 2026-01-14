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

# Load schedule DSL and registry (for SolidQueue integration)
require "active_data_flow/schedule_dsl"
require "active_data_flow/recurring_schedule_registry"
require "active_data_flow/runtime_registry"

# Load flow callbacks and bulk enqueue (for flow coordination)
require "active_data_flow/flow_callbacks"
require "active_data_flow/bulk_enqueue"

# Load error handling, instrumentation, and metrics (Phase 5)
require "active_data_flow/error_handling"
require "active_data_flow/instrumentation"
require "active_data_flow/metrics"
require "active_data_flow/solid_queue_dashboard"

