# frozen_string_literal: true

module ActiveDataFlow
  module Runtime
    module Heartbeat
      # Heartbeat-specific flow executor.
      # Inherits shared execution logic from Runtime::FlowExecutor.
      class FlowRunExecutor < Runtime::FlowExecutor
        # Uses default run_flow which delegates to @data_flow.run
      end
    end
  end
end
