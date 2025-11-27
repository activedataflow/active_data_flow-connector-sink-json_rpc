# frozen_string_literal: true

module ActiveDataFlow
  module RailsHeartbeatApp
      class DataFlowsControllerBase < ActionController::Base
        
        def status
          # Log state of all flows and their pending runs
          all_flows = DataFlow.all
          Rails.logger.info "[Heartbeat] Total flows: #{all_flows.count}"
          
          all_flows.each do |flow|
            pending_runs = flow.data_flow_runs.pending.count
            next_run = flow.data_flow_runs.pending.where('run_after <= ?', Time.current).order(:run_after).first
            
            if next_run
              Rails.logger.info "[Heartbeat] Flow: #{flow.name} | Status: #{flow.status} | Pending runs: #{pending_runs} | Next due: now"
            else
              future_run = flow.data_flow_runs.pending.where('run_after > ?', Time.current).order(:run_after).first
              if future_run
                seconds_until = (future_run.run_after - Time.current).to_i
                Rails.logger.info "[Heartbeat] Flow: #{flow.name} | Status: #{flow.status} | Pending runs: #{pending_runs} | Next run in: #{seconds_until}s"
              else
                Rails.logger.info "[Heartbeat] Flow: #{flow.name} | Status: #{flow.status} | No pending runs scheduled"
              end
            end
          end
        end

        def heartbeat
          this_result = ActiveDataFlow::heartbeat::ThisHeartbeat.call
          next_result = ActiveDataFlow::heartbeat::NextHeartbeat.call
          render json: {
            this_result: this_result,
            next_result: next_result
          }
        rescue => e
          Rails.logger.error "[Heartbeat] Heartbeat failed: #{e.message}"
          Rails.logger.error e.backtrace.first(10).join("\n")
          render json: { error: e.message }, status: :internal_server_error
        end
      end
    end
  end
end
