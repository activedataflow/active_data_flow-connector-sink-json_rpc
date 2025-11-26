# frozen_string_literal: true

namespace :active_data_flow do
  desc "Run all due data flows"
  task run_due: :environment do
    puts "Checking for due data flows..."
    ActiveDataFlow::SchedulerService.run_due_flows
    puts "Completed running due data flows"
  end

  desc "Show status of all data flows"
  task status: :environment do
    puts "\n=== ActiveDataFlow Status ==="
    
    ActiveDataFlow::DataFlow.includes(:data_flow_runs).find_each do |flow|
      puts "\nFlow: #{flow.name}"
      puts "  Status: #{flow.status}"
      puts "  Enabled: #{flow.enabled?}"
      puts "  Interval: #{flow.interval_seconds}s"
      puts "  Last run: #{flow.last_run_at || 'Never'}"
      
      pending_runs = flow.data_flow_runs.pending.count
      due_runs = flow.data_flow_runs.due.count
      
      puts "  Pending runs: #{pending_runs}"
      puts "  Due runs: #{due_runs}"
      
      if flow.next_due_run
        puts "  Next due run: #{flow.next_due_run.run_after}"
      end
    end
    
    puts "\n=== Recent Runs ==="
    ActiveDataFlow::DataFlowRun.includes(:data_flow)
                               .order(created_at: :desc)
                               .limit(10)
                               .each do |run|
      puts "#{run.data_flow.name}: #{run.status} (#{run.run_after})"
    end
  end

  desc "Cleanup old data flow runs (older than 30 days)"
  task cleanup: :environment do
    puts "Cleaning up old data flow runs..."
    deleted_count = ActiveDataFlow::SchedulerService.new.cleanup_old_runs
    puts "Deleted #{deleted_count} old runs"
  end

  desc "Register all data flows"
  task register: :environment do
    puts "Registering data flows..."
    
    # This would typically be done automatically when flows are loaded
    # but this task can be used to manually register flows
    Rails.application.eager_load!
    
    # Find all classes that include ActiveRecord2ActiveRecord
    flow_classes = ObjectSpace.each_object(Class).select do |klass|
      klass < Object && klass.included_modules.include?(ActiveDataFlow::ActiveRecord2ActiveRecord)
    end
    
    flow_classes.each do |flow_class|
      puts "Registering #{flow_class.name}..."
      flow_class.new # This triggers registration
    end
    
    puts "Registration complete"
  end
end