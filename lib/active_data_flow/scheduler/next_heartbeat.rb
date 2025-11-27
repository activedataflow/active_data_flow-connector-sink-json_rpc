# frozen_string_literal: true

module ActiveDataFlow
  module Scheduler
    # Handles heartbeat-based scheduling for ActiveDataFlow
    # 
    # This class is responsible for:
    # - Finding flows that are due to run based on their heartbeat schedule
    # - Executing due flows with proper error handling and logging
    # - Managing the lifecycle of data flow runs
    class NextHeartbeat
      def self.call
        new.call
      end

      def call
        result = {
            processed_runs: 0,
            success_count: 0,
            error_count: 0,
            timestamp: Time.current
        }

        Rails.logger.info "[Heartbeat] Starting heartbeat check at #{Time.current}"        
        due_runs = find_due_runs

        Rails.logger.info "[Heartbeat] Found #{due_runs.count} run(s) due for execution"
        
        if due_runs.empty?
          Rails.logger.info("[ActiveDataFlow::Scheduler] No runs due")
          return result
        end

        result[:processed_runs] = due_runs.count

        due_runs.each do |run|
          Rails.logger.info "[Heartbeat] Executing run #{run.id} for flow: #{run.data_flow.name}"
          
          begin
            ActiveDataFlow::Runtime::Heartbeat::FlowExecutor.execute(run)
            result[:success_count] += 1
            Rails.logger.info "[Heartbeat] Successfully executed run #{run.id}"
          rescue => e
            result[:error_count] += 1
            Rails.logger.error "[Heartbeat] Run #{run.id} execution failed: #{e.message}"
            Rails.logger.error e.backtrace.first(5).join("\n")
            # Continue with next run
          end
        end

        Rails.logger.info "[Heartbeat] Completed: #{result[:success_count]} success, #{result[:error_count]} errors"
      
        return result
      end

      private

      # Find all flows that have pending runs due to execute
      def find_due_runs
        # Query data_flow_runs that are due to execute
        DataFlowRun.pending.due
          .includes(:data_flow)
          .lock("FOR UPDATE SKIP LOCKED")
      end

    end
  end
end