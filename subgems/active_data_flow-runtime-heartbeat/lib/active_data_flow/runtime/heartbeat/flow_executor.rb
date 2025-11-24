# frozen_string_literal: true

module ActiveDataFlow
  module Runtime
    module Heartbeat
      class FlowExecutor
        def self.execute(data_flow)
          new(data_flow).execute
        end

        def initialize(data_flow)
          @data_flow = data_flow
        end

        def execute
          Rails.logger.info "[FlowExecutor] Starting execution for: #{data_flow.name}"
          
          data_flow.mark_run_started!
          
          # Get the flow class from the name
          flow_class_name = data_flow.name.camelize
          
          unless Object.const_defined?(flow_class_name)
            raise "Flow class #{flow_class_name} not found"
          end
          
          flow_class = Object.const_get(flow_class_name)
          flow_instance = flow_class.new
          
          Rails.logger.info "[FlowExecutor] Running flow instance"
          flow_instance.run
          
          Rails.logger.info "[FlowExecutor] Flow completed successfully"
        rescue => e
          Rails.logger.error "[FlowExecutor] Flow failed: #{e.message}"
          data_flow.mark_run_failed!(e)
          raise
        end

        private

        attr_reader :data_flow
      end
    end
  end
end
