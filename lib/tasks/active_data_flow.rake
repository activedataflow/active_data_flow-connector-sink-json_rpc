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

  namespace :active_job do
    desc "Enqueue all active flows for immediate execution via ActiveJob"
    task enqueue_all: :environment do
      count = 0
      ActiveDataFlow::DataFlow.active.find_each do |flow|
        if flow.enabled?
          job = ActiveDataFlow::DataFlowJob.perform_later(flow.id)
          puts "Enqueued: #{flow.name} (job_id: #{job.job_id})"
          count += 1
        else
          puts "Skipped (disabled): #{flow.name}"
        end
      end
      puts "\nEnqueued #{count} data flow(s)"
    end

    desc "Enqueue a specific flow by name"
    task :enqueue, [:name] => :environment do |_, args|
      unless args[:name]
        puts "Usage: rake active_data_flow:active_job:enqueue[flow_name]"
        exit 1
      end

      flow = ActiveDataFlow::DataFlow.find_by(name: args[:name])
      unless flow
        puts "Flow not found: #{args[:name]}"
        exit 1
      end

      if flow.enabled?
        job = ActiveDataFlow::DataFlowJob.perform_later(flow.id)
        puts "Enqueued flow '#{flow.name}' as job #{job.job_id}"
      else
        puts "Flow '#{flow.name}' is disabled"
      end
    end

    desc "Schedule a flow for execution at a specific time"
    task :schedule, [:name, :delay_seconds] => :environment do |_, args|
      unless args[:name] && args[:delay_seconds]
        puts "Usage: rake active_data_flow:active_job:schedule[flow_name,delay_seconds]"
        exit 1
      end

      flow = ActiveDataFlow::DataFlow.find_by(name: args[:name])
      unless flow
        puts "Flow not found: #{args[:name]}"
        exit 1
      end

      delay = args[:delay_seconds].to_i
      run_at = Time.current + delay.seconds

      if flow.enabled?
        job = ActiveDataFlow::DataFlowJob.set(wait: delay.seconds).perform_later(flow.id)
        puts "Scheduled flow '#{flow.name}' for #{run_at} (job_id: #{job.job_id})"
      else
        puts "Flow '#{flow.name}' is disabled"
      end
    end

    desc "Show ActiveJob queue status for data flows"
    task queue_status: :environment do
      puts "\n=== ActiveJob Queue Status ==="

      if defined?(SolidQueue)
        pending = SolidQueue::Job.where(queue_name: "active_data_flow").count
        puts "SolidQueue pending jobs: #{pending}"
      else
        puts "Queue adapter: #{ActiveJob::Base.queue_adapter.class.name}"
        puts "(Detailed queue stats not available for this adapter)"
      end

      puts "\n=== Recent DataFlowJob Executions ==="
      ActiveDataFlow::DataFlowRun.includes(:data_flow)
                                 .where(status: %w[success failed in_progress])
                                 .order(started_at: :desc)
                                 .limit(10)
                                 .each do |run|
        duration = if run.ended_at && run.started_at
                     "#{(run.ended_at - run.started_at).round(2)}s"
                   else
                     "running"
                   end
        puts "  #{run.data_flow.name}: #{run.status} (#{duration})"
      end
    end
  end

  namespace :schedules do
    desc "Sync data flow schedules to config/recurring.yml for SolidQueue"
    task sync: :environment do
      puts "=== Syncing ActiveDataFlow Schedules ==="
      puts ""

      # Load flow classes to populate the registry
      puts "Loading data flow classes..."
      if defined?(ActiveDataFlow::DataFlowsFolder)
        ActiveDataFlow::DataFlowsFolder.load_host_concerns_and_flows
      end

      dsl_count = ActiveDataFlow::RecurringScheduleRegistry.entries.size
      puts "  Found #{dsl_count} flow(s) with DSL schedules"

      # Also scan database for flows with ActiveJob runtime
      puts ""
      puts "Scanning database for flows with ActiveJob runtime..."
      begin
        db_count = ActiveDataFlow::RecurringScheduleRegistry.register_from_database
        puts "  Found #{db_count} flow(s) configured in database"
      rescue StandardError => e
        puts "  Could not scan database: #{e.message}"
      end

      # Generate the recurring.yml
      puts ""
      output_path = Rails.root.join("config", "recurring.yml")
      puts "Generating #{output_path}..."

      result = ActiveDataFlow::RecurringScheduleRegistry.sync_to_file(
        path: output_path,
        merge: true
      )

      if result[:written]
        puts "  ✓ Created/updated: #{result[:path]}"
        if result[:entries].any?
          puts ""
          puts "  Entries:"
          result[:entries].each { |e| puts "    - #{e}" }
        end

        if result[:preserved_entries]&.any?
          puts ""
          puts "  Preserved existing entries:"
          result[:preserved_entries].each { |e| puts "    - #{e}" }
        end
      else
        puts "  ✗ Failed to write file"
        exit 1
      end

      puts ""
      puts "Done! Run 'bin/jobs' to start the SolidQueue scheduler."
    end

    desc "Show registered schedules without writing to file"
    task list: :environment do
      puts "=== Registered ActiveDataFlow Schedules ==="
      puts ""

      # Load flow classes
      if defined?(ActiveDataFlow::DataFlowsFolder)
        ActiveDataFlow::DataFlowsFolder.load_host_concerns_and_flows
      end

      # Scan database
      begin
        ActiveDataFlow::RecurringScheduleRegistry.register_from_database
      rescue StandardError
        # Ignore database errors for listing
      end

      entries = ActiveDataFlow::RecurringScheduleRegistry.entries

      if entries.empty?
        puts "No schedules registered."
        puts ""
        puts "To add a schedule, include ScheduleDSL in your flow class:"
        puts ""
        puts "  class MyFlow < ActiveDataFlow::DataFlow"
        puts "    include ActiveDataFlow::ScheduleDSL"
        puts ""
        puts "    schedule every: 5.minutes"
        puts "  end"
      else
        entries.each do |class_name, entry|
          config = entry[:config]
          source = entry[:source] || :dsl

          puts "#{class_name}:"
          puts "  Source: #{source}"

          if config[:every]
            interval = config[:every]
            interval_str = interval.is_a?(ActiveSupport::Duration) ? interval.inspect : "#{interval}s"
            puts "  Schedule: every #{interval_str}"
          elsif config[:cron]
            puts "  Schedule: #{config[:cron]}"
          elsif config[:at]
            puts "  Schedule: at #{config[:at]}"
          end

          puts "  Queue: #{config[:queue] || 'active_data_flow'}"
          puts "  Priority: #{config[:priority]}" if config[:priority]
          puts ""
        end
      end
    end

    desc "Clear the schedule registry (does not modify recurring.yml)"
    task clear: :environment do
      ActiveDataFlow::RecurringScheduleRegistry.clear!
      puts "Schedule registry cleared."
    end

    desc "Validate recurring.yml syntax"
    task validate: :environment do
      path = Rails.root.join("config", "recurring.yml")

      unless path.exist?
        puts "No recurring.yml found at #{path}"
        exit 1
      end

      begin
        config = YAML.safe_load(path.read, permitted_classes: [Symbol])
        puts "✓ recurring.yml is valid YAML"
        puts ""
        puts "Entries: #{config&.keys&.join(', ') || 'none'}"
      rescue Psych::SyntaxError => e
        puts "✗ Invalid YAML: #{e.message}"
        exit 1
      end
    end

    desc "Show diff between registry and recurring.yml"
    task diff: :environment do
      path = Rails.root.join("config", "recurring.yml")

      # Load registry
      if defined?(ActiveDataFlow::DataFlowsFolder)
        ActiveDataFlow::DataFlowsFolder.load_host_concerns_and_flows
      end

      begin
        ActiveDataFlow::RecurringScheduleRegistry.register_from_database
      rescue StandardError
        # Ignore
      end

      registry_config = ActiveDataFlow::RecurringScheduleRegistry.to_config
      registry_keys = registry_config.keys.to_set

      # Load existing file
      file_config = if path.exist?
                      YAML.safe_load(path.read, permitted_classes: [Symbol]) || {}
                    else
                      {}
                    end
      file_keys = file_config.keys.to_set

      puts "=== Schedule Diff ==="
      puts ""

      new_entries = registry_keys - file_keys
      removed_entries = file_keys - registry_keys
      common_entries = registry_keys & file_keys

      if new_entries.any?
        puts "New (will be added):"
        new_entries.each { |e| puts "  + #{e}" }
        puts ""
      end

      if removed_entries.any?
        puts "In file but not in registry (will be preserved):"
        removed_entries.each { |e| puts "  ? #{e}" }
        puts ""
      end

      if common_entries.any?
        puts "Existing (will be updated):"
        common_entries.each { |e| puts "  = #{e}" }
        puts ""
      end

      if new_entries.empty? && removed_entries.empty?
        puts "No changes needed."
      else
        puts "Run 'rails active_data_flow:schedules:sync' to apply changes."
      end
    end
  end

  namespace :bulk do
    desc "Enqueue all active flows via BulkEnqueue"
    task enqueue_all: :environment do
      puts "=== Bulk Enqueue All Active Flows ==="
      puts ""

      result = ActiveDataFlow::BulkEnqueue.enqueue_all_active
      puts "Enqueued: #{result[:enqueued]} / #{result[:total] || result[:enqueued]} flows"

      if result[:bulk]
        puts "Method: bulk (perform_all_later)"
      else
        puts "Method: sequential"
      end

      if result[:jobs]&.any?
        puts ""
        puts "Jobs:"
        result[:jobs].each do |job|
          puts "  - #{job.job_id}"
        end
      end
    end

    desc "Enqueue all flows in a concurrency group"
    task :enqueue_group, [:group_name] => :environment do |_, args|
      unless args[:group_name]
        puts "Usage: rake active_data_flow:bulk:enqueue_group[group_name]"
        exit 1
      end

      puts "=== Bulk Enqueue Group: #{args[:group_name]} ==="
      puts ""

      result = ActiveDataFlow::BulkEnqueue.enqueue_group(args[:group_name])
      puts "Enqueued: #{result[:enqueued]} flows in group '#{result[:group]}'"
    end

    desc "Enqueue specific flows by name (comma-separated)"
    task :enqueue_flows, [:names] => :environment do |_, args|
      unless args[:names]
        puts "Usage: rake active_data_flow:bulk:enqueue_flows[flow1,flow2,flow3]"
        exit 1
      end

      names = args[:names].split(",").map(&:strip)
      puts "=== Bulk Enqueue Flows: #{names.join(', ')} ==="
      puts ""

      result = ActiveDataFlow::BulkEnqueue.enqueue_flows(names)
      puts "Enqueued: #{result[:enqueued]} / #{names.size} flows"

      if result[:not_found]&.any?
        puts ""
        puts "Not found:"
        result[:not_found].each { |n| puts "  - #{n}" }
      end
    end

    desc "Enqueue flows with staggered start times"
    task :enqueue_staggered, [:interval_seconds] => :environment do |_, args|
      interval = (args[:interval_seconds] || 10).to_i
      puts "=== Staggered Enqueue (#{interval}s interval) ==="
      puts ""

      flows = ActiveDataFlow::DataFlow.active.select(&:enabled?)
      result = ActiveDataFlow::BulkEnqueue.enqueue_staggered(flows, interval: interval.seconds)

      puts "Scheduled: #{result[:scheduled]} flows"
      puts "Interval: #{result[:interval]}"
      puts ""

      if result[:schedule]&.any?
        puts "Schedule:"
        result[:schedule].each do |entry|
          puts "  #{entry[:flow]}: #{entry[:run_at].strftime('%H:%M:%S')}"
        end
      end
    end

    desc "Show concurrency groups and their flows"
    task groups: :environment do
      puts "=== Concurrency Groups ==="
      puts ""

      groups = Hash.new { |h, k| h[k] = [] }
      ungrouped = []

      ActiveDataFlow::DataFlow.active.each do |flow|
        group = flow.concurrency_group
        if group.present?
          groups[group] << flow
        else
          ungrouped << flow
        end
      end

      if groups.any?
        groups.each do |group_name, flows|
          limit = flows.first.concurrency_group_limit || "default"
          puts "#{group_name} (limit: #{limit}):"
          flows.each do |flow|
            puts "  - #{flow.name}"
          end
          puts ""
        end
      end

      if ungrouped.any?
        puts "Ungrouped (individual concurrency):"
        ungrouped.each do |flow|
          limit = flow.concurrency_limit
          puts "  - #{flow.name} (limit: #{limit})"
        end
      end

      if groups.empty? && ungrouped.empty?
        puts "No active flows found."
      end
    end
  end

  namespace :continuations do
    desc "Check if ActiveJob::Continuable is available"
    task check: :environment do
      puts "=== ActiveJob Continuations Status ==="
      puts ""

      if defined?(ActiveJob::Continuable)
        puts "✓ ActiveJob::Continuable is available (Rails 8.1+)"
        puts ""
        puts "You can enable continuations for flows:"
        puts ""
        puts "  runtime = ActiveDataFlow::Runtime::ActiveJob.new("
        puts "    use_continuations: true,"
        puts "    max_resumptions: 10"
        puts "  )"
      else
        puts "✗ ActiveJob::Continuable is not available"
        puts ""
        puts "Continuations require Rails 8.1 or later."
        puts "Current Rails version: #{Rails.version}"
      end
    end

    desc "Show flows with continuations enabled"
    task list: :environment do
      puts "=== Flows with Continuations Enabled ==="
      puts ""

      continuation_flows = []
      standard_flows = []

      ActiveDataFlow::DataFlow.active.each do |flow|
        runtime = flow.parsed_runtime
        if runtime&.dig("use_continuations")
          continuation_flows << flow
        else
          standard_flows << flow
        end
      end

      if continuation_flows.any?
        puts "Continuation-enabled flows:"
        continuation_flows.each do |flow|
          runtime = flow.parsed_runtime
          max = runtime["max_resumptions"] || "unlimited"
          puts "  - #{flow.name} (max_resumptions: #{max})"
        end
      else
        puts "No flows with continuations enabled."
      end

      puts ""
      puts "Standard flows: #{standard_flows.size}"
    end

    desc "Show progress of in-progress continuation jobs"
    task progress: :environment do
      puts "=== In-Progress Continuation Jobs ==="
      puts ""

      in_progress_runs = ActiveDataFlow::DataFlowRun.in_progress.includes(:data_flow)

      if in_progress_runs.empty?
        puts "No in-progress runs found."
      else
        in_progress_runs.each do |run|
          puts "#{run.data_flow.name} (run ##{run.id}):"

          if run.respond_to?(:progress) && run.progress.any?
            progress = run.progress
            puts "  Step: #{progress[:step] || 'unknown'}"
            puts "  Cursor: #{progress[:cursor] || 'none'}"
            puts "  Records processed: #{progress[:records_processed] || 0}"
            puts "  Resumptions: #{progress[:resumptions] || 0}"
          else
            puts "  No progress tracking data available"
          end

          if run.started_at
            elapsed = Time.current - run.started_at
            puts "  Elapsed: #{elapsed.round(1)}s"
          end
          puts ""
        end
      end
    end

    desc "Show resumable runs (interrupted continuations)"
    task resumable: :environment do
      puts "=== Resumable Runs ==="
      puts ""

      resumable_runs = ActiveDataFlow::DataFlowRun.in_progress.select do |run|
        run.respond_to?(:resumable?) && run.resumable?
      end

      if resumable_runs.empty?
        puts "No resumable runs found."
      else
        resumable_runs.each do |run|
          puts "#{run.data_flow.name} (run ##{run.id}):"
          puts "  Cursor: #{run.current_cursor}"
          puts "  Records: #{run.records_processed || 0}"
          puts "  To resume: rails active_data_flow:continuations:resume[#{run.id}]"
          puts ""
        end
      end
    end

    desc "Resume a specific run by ID"
    task :resume, [:run_id] => :environment do |_, args|
      unless args[:run_id]
        puts "Usage: rake active_data_flow:continuations:resume[run_id]"
        exit 1
      end

      run = ActiveDataFlow::DataFlowRun.find_by(id: args[:run_id])
      unless run
        puts "Run not found: #{args[:run_id]}"
        exit 1
      end

      unless run.in_progress?
        puts "Run is not in progress (status: #{run.status})"
        exit 1
      end

      flow = run.data_flow
      runtime = flow.parsed_runtime

      if runtime&.dig("use_continuations")
        job = ActiveDataFlow::ContinuableDataFlowJob.perform_later(flow.id, run_id: run.id)
        puts "Resumed run ##{run.id} for flow '#{flow.name}'"
        puts "Job ID: #{job.job_id}"
      else
        job = ActiveDataFlow::DataFlowJob.perform_later(flow.id, run_id: run.id)
        puts "Enqueued run ##{run.id} for flow '#{flow.name}' (standard job)"
        puts "Job ID: #{job.job_id}"
      end
    end

    desc "Enable continuations for a flow"
    task :enable, [:flow_name] => :environment do |_, args|
      unless args[:flow_name]
        puts "Usage: rake active_data_flow:continuations:enable[flow_name]"
        exit 1
      end

      flow = ActiveDataFlow::DataFlow.find_by(name: args[:flow_name])
      unless flow
        puts "Flow not found: #{args[:flow_name]}"
        exit 1
      end

      runtime = flow.parsed_runtime || {}
      runtime["use_continuations"] = true
      runtime["class_name"] ||= "ActiveDataFlow::Runtime::ActiveJob"

      flow.update!(runtime: runtime)
      puts "✓ Continuations enabled for flow: #{flow.name}"
    end

    desc "Disable continuations for a flow"
    task :disable, [:flow_name] => :environment do |_, args|
      unless args[:flow_name]
        puts "Usage: rake active_data_flow:continuations:disable[flow_name]"
        exit 1
      end

      flow = ActiveDataFlow::DataFlow.find_by(name: args[:flow_name])
      unless flow
        puts "Flow not found: #{args[:flow_name]}"
        exit 1
      end

      runtime = flow.parsed_runtime || {}
      runtime.delete("use_continuations")
      runtime.delete("max_resumptions")

      flow.update!(runtime: runtime)
      puts "✓ Continuations disabled for flow: #{flow.name}"
    end
  end

  namespace :errors do
    desc "Show recent errors across all flows"
    task recent: :environment do
      puts "=== Recent ActiveDataFlow Errors (Last 24h) ==="
      puts ""

      errors = ActiveDataFlow::ErrorHandling::ErrorTracker.recent_errors(limit: 50)

      if errors.empty?
        puts "No errors recorded in the last 24 hours."
      else
        errors.reverse_each do |error|
          puts "#{error[:occurred_at]}"
          puts "  Flow: #{error[:flow_name]} (run: #{error[:run_id] || 'N/A'})"
          puts "  Error: #{error[:error_class]}: #{error[:error_message]&.truncate(80)}"
          puts "  Classification: #{error[:error_classification]}"
          puts "  Attempt: #{error[:attempt]}"
          puts ""
        end
      end
    end

    desc "Show errors for a specific flow"
    task :for_flow, [:flow_name] => :environment do |_, args|
      unless args[:flow_name]
        puts "Usage: rake active_data_flow:errors:for_flow[flow_name]"
        exit 1
      end

      puts "=== Errors for Flow: #{args[:flow_name]} ==="
      puts ""

      errors = ActiveDataFlow::ErrorHandling::ErrorTracker.recent_errors(
        flow_name: args[:flow_name],
        limit: 50
      )

      if errors.empty?
        puts "No errors recorded for this flow."
      else
        errors.reverse_each do |error|
          puts "#{error[:occurred_at]} (run: #{error[:run_id] || 'N/A'})"
          puts "  #{error[:error_class]}: #{error[:error_message]&.truncate(100)}"
          puts "  Attempt: #{error[:attempt]}, Classification: #{error[:error_classification]}"
          if error[:backtrace]&.any?
            puts "  Backtrace:"
            error[:backtrace].first(3).each { |line| puts "    #{line}" }
          end
          puts ""
        end
      end
    end

    desc "Show error statistics"
    task stats: :environment do
      puts "=== Error Statistics (Last 24h) ==="
      puts ""

      stats = ActiveDataFlow::ErrorHandling::ErrorTracker.statistics

      puts "Total errors: #{stats[:total_24h]}"
      puts ""

      if stats[:by_flow]&.any?
        puts "By Flow:"
        stats[:by_flow].sort_by { |_, v| -v }.each do |flow, count|
          puts "  #{flow}: #{count}"
        end
        puts ""
      end

      if stats[:by_classification]&.any?
        puts "By Classification:"
        stats[:by_classification].each do |classification, count|
          puts "  #{classification}: #{count}"
        end
        puts ""
      end

      if stats[:by_error_class]&.any?
        puts "By Error Class:"
        stats[:by_error_class].sort_by { |_, v| -v }.first(10).each do |error_class, count|
          puts "  #{error_class}: #{count}"
        end
      end
    end

    desc "Cleanup old error records"
    task cleanup: :environment do
      puts "Cleaning up old error records..."
      ActiveDataFlow::ErrorHandling::ErrorTracker.cleanup!
      puts "Done."
    end

    desc "Show error handling configuration"
    task config: :environment do
      puts "=== Error Handling Configuration ==="
      puts ""

      config = ActiveDataFlow::ErrorHandling.configuration

      puts "Max Attempts: #{config.max_attempts}"
      puts "Retry Wait: #{config.retry_wait}"
      puts "Retry Jitter: #{config.retry_jitter}"
      puts "Error TTL: #{config.error_ttl.inspect}"
      puts "Track Errors: #{config.track_errors}"
      puts ""

      puts "Transient Errors (will retry):"
      config.transient_errors.each { |e| puts "  - #{e}" }
      puts ""

      puts "Permanent Errors (will discard):"
      config.permanent_errors.each { |e| puts "  - #{e}" }
    end
  end

  namespace :metrics do
    desc "Show system-wide metrics"
    task system: :environment do
      puts "=== ActiveDataFlow System Metrics ==="
      puts ""

      stats = ActiveDataFlow::Metrics.system_stats

      puts "Period: #{stats[:period]}"
      puts ""
      puts "Flows:"
      puts "  Total: #{stats[:total_flows]}"
      puts "  Active: #{stats[:active_flows]}"
      puts "  Enabled: #{stats[:enabled_flows]}"
      puts ""
      puts "Runs:"
      puts "  Total: #{stats[:total_runs]}"
      puts "  Completed: #{stats[:completed_runs]}"
      puts "  Failed: #{stats[:failed_runs]}"
      puts "  In Progress: #{stats[:in_progress_runs]}"
      puts "  Pending: #{stats[:pending_runs]}"
      puts ""
      puts "Success Rate: #{stats[:success_rate]}%"
      puts "Avg Duration: #{stats[:avg_duration] ? "#{stats[:avg_duration]}s" : 'N/A'}"
      puts "Errors (24h): #{stats[:errors_24h]}"
    end

    desc "Show metrics for a specific flow"
    task :flow, [:flow_name] => :environment do |_, args|
      unless args[:flow_name]
        puts "Usage: rake active_data_flow:metrics:flow[flow_name]"
        exit 1
      end

      puts "=== Metrics for Flow: #{args[:flow_name]} ==="
      puts ""

      stats = ActiveDataFlow::Metrics.flow_stats(args[:flow_name])

      puts "Period: #{stats[:period]}"
      puts ""
      puts "Runs:"
      puts "  Total: #{stats[:total_runs]}"
      puts "  Completed: #{stats[:completed]}"
      puts "  Failed: #{stats[:failed]}"
      puts "  In Progress: #{stats[:in_progress]}"
      puts ""
      puts "Success Rate: #{stats[:success_rate]}%"
      puts "Avg Duration: #{stats[:avg_duration] ? "#{stats[:avg_duration]}s" : 'N/A'}"
      puts "Total Records: #{stats[:total_records]}"
      puts "Throughput: #{stats[:throughput_per_hour]} records/hour"
      puts ""
      puts "Last Run: #{stats[:last_run_at] || 'Never'}"
      puts "Last Success: #{stats[:last_success_at] || 'Never'}"
      puts "Last Failure: #{stats[:last_failure_at] || 'Never'}"
    end

    desc "Show queue metrics"
    task queue: :environment do
      puts "=== Queue Metrics ==="
      puts ""

      stats = ActiveDataFlow::Metrics.queue_stats

      puts "Queue Adapter: #{stats[:queue_adapter]}"

      if stats[:message]
        puts stats[:message]
      elsif stats[:error]
        puts "Error: #{stats[:error]}"
      else
        puts ""
        puts "Pending Jobs: #{stats[:pending_jobs]}"
        puts "ActiveDataFlow Jobs: #{stats[:active_data_flow_jobs]}"
        puts "Claimed Jobs: #{stats[:claimed_jobs]}"
        puts "Failed Jobs: #{stats[:failed_jobs]}"
        puts "Scheduled Jobs: #{stats[:scheduled_jobs]}"
        puts "Recurring Tasks: #{stats[:recurring_tasks]}"
      end
    end

    desc "Show throughput over time"
    task throughput: :environment do
      puts "=== Throughput (Last 24 Hours) ==="
      puts ""

      series = ActiveDataFlow::Metrics.throughput_series(period: 24.hours, interval: 1.hour)

      if series.empty?
        puts "No data available."
      else
        series.each do |bucket|
          time = Time.parse(bucket[:timestamp]).strftime("%H:%M")
          bar = "█" * [bucket[:completed], 50].min
          puts "#{time} | #{bar.ljust(50)} #{bucket[:completed]} runs (#{bucket[:records]} records)"
        end
      end
    end
  end

  namespace :health do
    desc "Run a health check"
    task check: :environment do
      puts "=== ActiveDataFlow Health Check ==="
      puts ""

      health = ActiveDataFlow::Metrics.health_check

      status_icon = case health[:status]
                    when :healthy then "✓"
                    when :degraded then "⚠"
                    when :critical then "✗"
                    else "?"
                    end

      puts "Overall Status: #{status_icon} #{health[:status].to_s.upcase}"
      puts "Timestamp: #{health[:timestamp]}"
      puts ""

      health[:checks].each do |check_name, result|
        icon = case result[:status]
               when :healthy then "✓"
               when :degraded then "⚠"
               when :critical then "✗"
               else "?"
               end

        puts "#{icon} #{check_name.to_s.titleize}: #{result[:message]}"

        result.except(:status, :message).each do |key, value|
          puts "    #{key}: #{value}"
        end
      end

      exit 1 if health[:status] == :critical
    end

    desc "Run health check and output JSON"
    task :json => :environment do
      health = ActiveDataFlow::Metrics.health_check
      puts JSON.pretty_generate(health)

      exit 1 if health[:status] == :critical
    end
  end

  namespace :dashboard do
    desc "Show SolidQueue dashboard overview"
    task overview: :environment do
      puts "=== SolidQueue Dashboard ==="
      puts ""

      overview = ActiveDataFlow::SolidQueueDashboard.overview

      unless overview[:available]
        puts overview[:message] || overview[:error] || "SolidQueue not available"
        exit 0
      end

      puts "Timestamp: #{overview[:timestamp]}"
      puts ""
      puts "Jobs:"
      puts "  Pending: #{overview[:pending_jobs]}"
      puts "  Claimed: #{overview[:claimed_jobs]}"
      puts "  Failed: #{overview[:failed_jobs]}"
      puts "  Scheduled: #{overview[:scheduled_jobs]}"
      puts "  Recurring Tasks: #{overview[:recurring_tasks]}"
      puts ""

      if overview[:jobs_by_queue]&.any?
        puts "By Queue:"
        overview[:jobs_by_queue].each do |queue, count|
          puts "  #{queue}: #{count}"
        end
        puts ""
      end

      if overview[:recent_failures]&.any?
        puts "Recent Failures:"
        overview[:recent_failures].each do |failure|
          puts "  Job #{failure[:job_id]}: #{failure[:error_class]}"
          puts "    #{failure[:error_message]}"
          puts ""
        end
      end
    end

    desc "Show pending jobs"
    task pending: :environment do
      puts "=== Pending ActiveDataFlow Jobs ==="
      puts ""

      jobs = ActiveDataFlow::SolidQueueDashboard.pending_jobs(limit: 20)

      if jobs.empty?
        puts "No pending jobs."
      else
        jobs.each do |job|
          puts "Job #{job[:id]}:"
          puts "  Class: #{job[:class_name]}"
          puts "  Queue: #{job[:queue_name]}"
          puts "  Scheduled: #{job[:scheduled_at] || 'immediate'}"
          puts "  Arguments: #{job[:arguments]}"
          puts ""
        end
      end
    end

    desc "Show failed jobs"
    task failed: :environment do
      puts "=== Failed ActiveDataFlow Jobs ==="
      puts ""

      jobs = ActiveDataFlow::SolidQueueDashboard.failed_jobs(limit: 20)

      if jobs.empty?
        puts "No failed jobs."
      else
        jobs.each do |job|
          puts "Job #{job[:job_id]}:"
          puts "  Error: #{job[:error_class]}"
          puts "  Message: #{job[:error_message]&.truncate(100)}"
          puts "  Failed at: #{job[:failed_at]}"
          puts "  To retry: rake active_data_flow:dashboard:retry[#{job[:job_id]}]"
          puts ""
        end
      end
    end

    desc "Show jobs for a specific flow"
    task :jobs_for, [:flow_name] => :environment do |_, args|
      unless args[:flow_name]
        puts "Usage: rake active_data_flow:dashboard:jobs_for[flow_name]"
        exit 1
      end

      puts "=== Jobs for Flow: #{args[:flow_name]} ==="
      puts ""

      jobs = ActiveDataFlow::SolidQueueDashboard.jobs_for_flow(args[:flow_name], limit: 20)

      if jobs.empty?
        puts "No jobs found for this flow."
      else
        jobs.each do |job|
          puts "Job #{job[:id]}: #{job[:status]}"
          puts "  Queue: #{job[:queue_name]}"
          puts "  Created: #{job[:created_at]}"
          puts ""
        end
      end
    end

    desc "Retry a failed job"
    task :retry, [:job_id] => :environment do |_, args|
      unless args[:job_id]
        puts "Usage: rake active_data_flow:dashboard:retry[job_id]"
        exit 1
      end

      if ActiveDataFlow::SolidQueueDashboard.retry_job(args[:job_id].to_i)
        puts "✓ Job #{args[:job_id]} has been retried."
      else
        puts "✗ Failed to retry job #{args[:job_id]}."
        exit 1
      end
    end

    desc "Retry all failed ActiveDataFlow jobs"
    task retry_all: :environment do
      puts "Retrying all failed ActiveDataFlow jobs..."

      count = ActiveDataFlow::SolidQueueDashboard.retry_all_failed
      puts "Retried #{count} job(s)."
    end

    desc "Discard a failed job"
    task :discard, [:job_id] => :environment do |_, args|
      unless args[:job_id]
        puts "Usage: rake active_data_flow:dashboard:discard[job_id]"
        exit 1
      end

      if ActiveDataFlow::SolidQueueDashboard.discard_job(args[:job_id].to_i)
        puts "✓ Job #{args[:job_id]} has been discarded."
      else
        puts "✗ Failed to discard job #{args[:job_id]}."
        exit 1
      end
    end

    desc "Show recurring tasks"
    task recurring: :environment do
      puts "=== Recurring ActiveDataFlow Tasks ==="
      puts ""

      tasks = ActiveDataFlow::SolidQueueDashboard.recurring_tasks

      if tasks.empty?
        puts "No recurring tasks configured."
      else
        tasks.each do |task|
          status = task[:paused] ? "(PAUSED)" : "(ACTIVE)"
          puts "#{task[:key]} #{status}:"
          puts "  Class: #{task[:class_name]}"
          puts "  Schedule: #{task[:schedule]}"
          puts "  Queue: #{task[:queue_name]}"
          puts "  Last enqueued: #{task[:last_enqueued_at] || 'Never'}"
          puts ""
        end
      end
    end

    desc "Pause all recurring tasks"
    task pause_all: :environment do
      puts "Pausing all recurring ActiveDataFlow tasks..."

      count = ActiveDataFlow::SolidQueueDashboard.pause_all_recurring
      puts "Paused #{count} task(s)."
    end

    desc "Resume all recurring tasks"
    task resume_all: :environment do
      puts "Resuming all recurring ActiveDataFlow tasks..."

      count = ActiveDataFlow::SolidQueueDashboard.resume_all_recurring
      puts "Resumed #{count} task(s)."
    end
  end
end