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
            success_runs: null,
            reschedule: 0,
            timestamp: Time.current
        }

        Rails.logger.info "[Heartbeat] Starting heartbeat success_runs check at #{Time.current}"        
        succcess_flows = find_success_flows

        Rails.logger.info "[Heartbeat] Found #{succcess_flows.count} succcess run(s) to reschedule"
        
        if succcess_flows.empty?
          Rails.logger.info("[ActiveDataFlow::Scheduler] No succcess_flows due to reschedule")
          return result
        end

        result[:success_runs] = succcess_flows.count
        result[:reschedule_count] = 0

        succcess_flows.each do |run|
          Rails.logger.info "[Heartbeat] rescheduling run #{run.id} for flow: #{run.data_flow.name}"
          
          ActiveDataFlow::Runtime::Heartbeat::FlowReschedule.execute(run)
          
          result[:reschedule_count] += 1
          Rails.logger.info "[Heartbeat] Successfully rescheduled run #{run.id}"
        rescue => e
          Rails.logger.error "[Heartbeat] Run #{run.id} reschedule failed: #{e.message}"
          Rails.logger.error e.backtrace.first(5).join("\n")
          # Continue with next run
        end

        Rails.logger.info "[Heartbeat] Completed: #{result[:reschedule_count]}/#{result[:success_runs]} runs executed"
      
        return result

      end

      private

      # Find all flows that have pending runs due to execute
      def find_success_flows
        # Query data_flow_runs that are due to execute
        DataFlowRun.success
          .includes(:data_flow)
          .lock("FOR UPDATE SKIP LOCKED")
      end

    end
  end
end