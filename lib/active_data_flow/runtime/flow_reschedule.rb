# frozen_string_literal: true

module ActiveDataFlow
  module Runtime
    # Shared flow rescheduling logic for all runtime backends.
    # Creates the next pending run for a data flow after completion.
    class FlowReschedule
      def self.execute(data_flow_run)
        new(data_flow_run).execute
      end

      def initialize(data_flow_run)
        @data_flow_run = data_flow_run
        @data_flow = data_flow_run.data_flow
      end

      def execute
        Rails.logger.info "[FlowReschedule] Starting reschedule for run #{@data_flow_run.id}: #{@data_flow.name}"
        DataFlowRun.create_pending_for_data_flow(@data_flow)
      end
    end
  end
end
