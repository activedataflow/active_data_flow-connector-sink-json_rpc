# frozen_string_literal: true

module ActiveDataFlow
  module Runtime
    module Heartbeat
      class DataFlowRunsController < ActionController::Base
        def heartbeat_event
          Rails.logger.info "[ActiveDataFlow::Runtime::Heartbeat::DataFlowsController.heartbeat_event] called"

          ::ActiveDataFlow::Runtime::Heartbeat::ScheduleFlowRuns.new.each_flow_run_due do |flow_run|
            FlowRunExecutor.execute(flow_run)
          end
        rescue => e
          Rails.logger.error("ActiveDataFlow::Runtime::Heartbeat.heartbeat failed: #{e.message}")
        end
      end
    end
  end
end
