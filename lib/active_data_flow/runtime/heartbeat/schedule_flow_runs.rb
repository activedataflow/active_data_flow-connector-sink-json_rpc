# frozen_string_literal: true

module ActiveDataFlow
  module Runtime
    module Heartbeat
      class ScheduleFlowRuns
        attr_accessor :data_flow_runs_due, :triggered_count

        def self.create
          new.execute
        end

        def initialize
          @triggered_count = 0
          @data_flow_runs_due = DataFlowRun.due_to_run
          Rails.logger.info "[ActiveDataFlow::Runtime::Heartbeat::ScheduleFlowRuns] initialized with #{@data_flow_runs_due.length} data_flow_runs_due"
        end

        def execute
          each_flow_run_due do |flow_run|
            FlowRunExecutor.execute(flow_run)
          end
        end

        def each_flow_run_due(&block)
          @data_flow_runs_due.each do |flow_run|
            Rails.logger.info "[ActiveDataFlow::Runtime::Heartbeat::ScheduleFlowRuns] each_flow_run_due.yield flow_run:#{flow_run}"
            yield(flow_run)
            @triggered_count += 1
          rescue => e
            Rails.logger.error("Flow Run execution failed at @triggered_count: #{@triggered_count}: #{e.message}")
            # Continue with next flow
          end
        end
      end
    end
  end
end
