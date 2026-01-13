# frozen_string_literal: true

module ActiveDataFlow
  module Runtime
    module Redcord
      class FlowExecutor
        def self.execute(data_flow_run)
          new(data_flow_run).execute
        end

        def initialize(data_flow_run)
          @data_flow_run = data_flow_run
          @data_flow = data_flow_run.data_flow
        end

        def execute
          Rails.logger.info "[FlowExecutor] Starting execution for run #{@data_flow_run.id}: #{@data_flow.name}"

          # Mark run as in progress and schedule next run
          @data_flow.mark_run_started!(@data_flow_run)

          # Get the flow class from the name
          flow_class_name = @data_flow.name.camelize

          unless Object.const_defined?(flow_class_name)
            raise "Flow class #{flow_class_name} not found"
          end

          flow_class = Object.const_get(flow_class_name)
          flow_instance = flow_class.new

          Rails.logger.info "[FlowExecutor] Running flow instance"
          flow_instance.run

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
