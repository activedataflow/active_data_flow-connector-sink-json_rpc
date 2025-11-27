# frozen_string_literal: true

module ActiveDataFlow
  module Scheduler
    # Handles heartbeat-based scheduling for ActiveDataFlow
    # 
    # This class is responsible for:
    # - Finding flows that are due to run based on their heartbeat schedule
    # - Executing due flows with proper error handling and logging
    # - Managing the lifecycle of data flow runs
    class ThisHeartbeat
      def self.call
        new.call
      end

      def call
        result = {
            runs_due: null,
            runs_triggered: 0,
            timestamp: Time.current
        }

        Rails.logger.info "[Heartbeat] Starting heartbeat due_runs check at #{Time.current}"        
        due_flows = find_due_flows

        Rails.logger.info "[Heartbeat] Found #{due_runs.count} run(s) due to execute"
        
        if due_flows.empty?
          Rails.logger.info("[ActiveDataFlow::Scheduler] No flows due to run")
          return result
        end

        result[:runs_due] = due_flows.count
        result[:triggered_count] = 0

        due_runs.each do |run|
          Rails.logger.info "[Heartbeat] Executing run #{run.id} for flow: #{run.data_flow.name}"
          
          ActiveDataFlow::Runtime::Heartbeat::FlowRescheduler.execute(run)
          
          result[:triggered_count] += 1
          Rails.logger.info "[Heartbeat] Successfully executed run #{run.id}"
        rescue => e
          Rails.logger.error "[Heartbeat] Run #{run.id} execution failed: #{e.message}"
          Rails.logger.error e.backtrace.first(5).join("\n")
          # Continue with next run
        end

        Rails.logger.info "[Heartbeat] Completed: #{result[:triggered_count]}/#{result[:runs_due]} runs executed"
      
        return result

      end

      private

      # Find all flows that have pending runs due to execute
      def find_due_flows
        # Query data_flow_runs that are due to execute
        DataFlowRun.pending
          .where('run_after <= ?', Time.current)
          .includes(:data_flow)
          .lock("FOR UPDATE SKIP LOCKED")
      end

    end
  end
end