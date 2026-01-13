# frozen_string_literal: true

module ActiveDataFlow
  module Runtime
    module Heartbeat
      class FlowRunExecutor
        def self.execute(data_flow_run)
          new(data_flow_run).execute
        end

        def initialize(data_flow_run)
          @data_flow_run = data_flow_run
          @data_flow = data_flow_run.data_flow
        end

        def execute
          Rails.logger.info "[FlowRunExecutor] Starting: #{@data_flow.name}: run #{@data_flow_run.id}"

          # Mark run as in progress and schedule next run
          @data_flow.mark_run_started!(@data_flow_run)

          Rails.logger.info "[FlowExecutor] Running flow instance"
          # Delegate execution to the data flow model, which handles casting/rehydration
          @data_flow.run

          # Mark run as successful
          @data_flow.mark_run_completed!(@data_flow_run)

          Rails.logger.info "[FlowExecutor] Flow completed successfully"
        rescue => e
          Rails.logger.error "[FlowExecutor] Flow failed: #{e.message}"
          # Mark run as failed
          @data_flow.mark_run_failed!(@data_flow_run, e)
          raise
        end
      end
    end
  end
end
