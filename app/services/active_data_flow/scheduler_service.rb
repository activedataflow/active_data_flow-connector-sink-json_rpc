# frozen_string_literal: true

module ActiveDataFlow
  class SchedulerService
    def self.run_due_flows
      new.run_due_flows
    end

    def run_due_flows
      DataFlow.due_to_run.find_each do |data_flow|
        run_record = data_flow.next_due_run
        next unless run_record

        Rails.logger.info("Running flow: #{data_flow.name} (run_id: #{run_record.id})")
        
        begin
          run_record.start!
          
          # Execute the flow logic here
          # This would typically instantiate the flow class and call run
          flow_class = data_flow.name.classify.constantize
          flow_instance = flow_class.new
          flow_instance.run
          
          run_record.complete!
          Rails.logger.info("Completed flow: #{data_flow.name} (run_id: #{run_record.id})")
        rescue StandardError => e
          run_record.fail!(e)
          Rails.logger.error("Failed flow: #{data_flow.name} (run_id: #{run_record.id}): #{e.message}")
          Rails.logger.error(e.backtrace.join("\n"))
        end
      end
    end

    def cleanup_old_runs(older_than: 30.days.ago)
      DataFlowRun.where(created_at: ..older_than).delete_all
    end
  end
end