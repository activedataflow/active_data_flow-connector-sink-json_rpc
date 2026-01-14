# frozen_string_literal: true

module ActiveDataFlow
  # Provides metrics collection and reporting for data flow execution.
  #
  # This module tracks execution statistics, throughput, and health indicators
  # that can be used for monitoring dashboards and alerting.
  #
  # @example Get flow statistics
  #   stats = ActiveDataFlow::Metrics.flow_stats("user_sync")
  #   puts "Success rate: #{stats[:success_rate]}%"
  #
  # @example Get overall health
  #   health = ActiveDataFlow::Metrics.health_check
  #   puts "Status: #{health[:status]}"
  #
  module Metrics
    class << self
      # Record a flow execution event
      #
      # @param event [Hash] Event payload from instrumentation
      def record(event)
        case event[:event_type]
        when :completed
          record_completion(event)
        when :failed
          record_failure(event)
        when :discarded
          record_discard(event)
        when :batch_processed
          record_batch(event)
        end
      end

      # Get statistics for a specific flow
      #
      # @param flow_name [String] The flow name
      # @param period [ActiveSupport::Duration] Time period (default: 24 hours)
      # @return [Hash] Flow statistics
      def flow_stats(flow_name, period: 24.hours)
        runs = fetch_runs_for_period(flow_name, period)

        {
          flow_name: flow_name,
          period: period.inspect,
          total_runs: runs.size,
          completed: runs.count(&:success?),
          failed: runs.count(&:failed?),
          in_progress: runs.count(&:in_progress?),
          success_rate: calculate_success_rate(runs),
          avg_duration: calculate_avg_duration(runs),
          total_records: calculate_total_records(runs),
          throughput_per_hour: calculate_throughput(runs, period),
          last_run_at: runs.max_by(&:started_at)&.started_at,
          last_success_at: runs.select(&:success?).max_by(&:ended_at)&.ended_at,
          last_failure_at: runs.select(&:failed?).max_by(&:ended_at)&.ended_at
        }
      end

      # Get overall system statistics
      #
      # @param period [ActiveSupport::Duration] Time period (default: 24 hours)
      # @return [Hash] System statistics
      def system_stats(period: 24.hours)
        cutoff = period.ago

        all_runs = ActiveDataFlow::DataFlowRun.where("created_at > ?", cutoff)
        all_flows = ActiveDataFlow::DataFlow.all

        {
          period: period.inspect,
          total_flows: all_flows.count,
          active_flows: all_flows.active.count,
          enabled_flows: all_flows.active.select(&:enabled?).count,
          total_runs: all_runs.count,
          completed_runs: all_runs.where(status: "success").count,
          failed_runs: all_runs.where(status: "failed").count,
          in_progress_runs: all_runs.where(status: "in_progress").count,
          pending_runs: all_runs.where(status: "pending").count,
          success_rate: calculate_success_rate(all_runs),
          avg_duration: calculate_avg_duration(all_runs),
          errors_24h: ErrorHandling::ErrorTracker.statistics[:total_24h]
        }
      end

      # Get queue statistics (SolidQueue integration)
      #
      # @return [Hash] Queue statistics
      def queue_stats
        stats = {
          queue_adapter: ActiveJob::Base.queue_adapter.class.name
        }

        if defined?(SolidQueue)
          stats.merge!(solid_queue_stats)
        else
          stats[:message] = "Detailed queue stats require SolidQueue"
        end

        stats
      end

      # Perform a health check
      #
      # @return [Hash] Health status
      def health_check
        checks = {
          database: check_database,
          queue: check_queue,
          flows: check_flows,
          error_rate: check_error_rate
        }

        overall_status = if checks.values.all? { |c| c[:status] == :healthy }
                           :healthy
                         elsif checks.values.any? { |c| c[:status] == :critical }
                           :critical
                         else
                           :degraded
                         end

        {
          status: overall_status,
          timestamp: Time.current.iso8601,
          checks: checks
        }
      end

      # Get throughput metrics
      #
      # @param period [ActiveSupport::Duration] Time period
      # @param interval [ActiveSupport::Duration] Bucket interval
      # @return [Array<Hash>] Throughput data points
      def throughput_series(period: 24.hours, interval: 1.hour)
        cutoff = period.ago
        runs = ActiveDataFlow::DataFlowRun.where("ended_at > ?", cutoff)
                                          .where(status: "success")

        buckets = []
        current = cutoff

        while current < Time.current
          bucket_end = current + interval
          bucket_runs = runs.select { |r| r.ended_at >= current && r.ended_at < bucket_end }

          buckets << {
            timestamp: current.iso8601,
            completed: bucket_runs.size,
            records: bucket_runs.sum { |r| r.records_processed || 0 }
          }

          current = bucket_end
        end

        buckets
      end

      private

      def fetch_runs_for_period(flow_name, period)
        flow = ActiveDataFlow::DataFlow.find_by(name: flow_name)
        return [] unless flow

        flow.data_flow_runs.where("created_at > ?", period.ago)
      end

      def calculate_success_rate(runs)
        completed = runs.count { |r| r.success? || r.failed? }
        return 0.0 if completed.zero?

        succeeded = runs.count(&:success?)
        ((succeeded.to_f / completed) * 100).round(2)
      end

      def calculate_avg_duration(runs)
        completed = runs.select { |r| r.started_at && r.ended_at }
        return nil if completed.empty?

        total = completed.sum { |r| r.ended_at - r.started_at }
        (total / completed.size).round(2)
      end

      def calculate_total_records(runs)
        runs.sum { |r| r.records_processed || 0 }
      end

      def calculate_throughput(runs, period)
        hours = period.to_i / 3600.0
        return 0.0 if hours.zero?

        total_records = calculate_total_records(runs)
        (total_records / hours).round(2)
      end

      def record_completion(event)
        increment_counter("completions", event[:flow_name])
        record_duration(event[:flow_name], event[:duration]) if event[:duration]
        record_records_processed(event[:flow_name], event[:records_processed]) if event[:records_processed]
      end

      def record_failure(event)
        increment_counter("failures", event[:flow_name])
        increment_counter("errors_by_class", event[:error_class])
      end

      def record_discard(event)
        increment_counter("discards", event[:flow_name])
      end

      def record_batch(event)
        increment_counter("batches", event[:flow_name])
        add_to_sum("records", event[:flow_name], event[:batch_size] || 0)
      end

      def increment_counter(metric, key)
        return unless Rails.cache

        cache_key = "adf:metrics:#{metric}:#{key}:#{Date.current}"
        Rails.cache.increment(cache_key, 1, expires_in: 2.days)
      end

      def add_to_sum(metric, key, value)
        return unless Rails.cache

        cache_key = "adf:metrics:#{metric}:#{key}:#{Date.current}"
        current = Rails.cache.read(cache_key) || 0
        Rails.cache.write(cache_key, current + value, expires_in: 2.days)
      end

      def record_duration(flow_name, duration)
        return unless Rails.cache

        cache_key = "adf:metrics:durations:#{flow_name}:#{Date.current}"
        durations = Rails.cache.read(cache_key) || []
        durations << duration
        durations = durations.last(1000) # Keep last 1000
        Rails.cache.write(cache_key, durations, expires_in: 2.days)
      end

      def record_records_processed(flow_name, count)
        add_to_sum("records_processed", flow_name, count)
      end

      def solid_queue_stats
        {
          pending_jobs: SolidQueue::Job.where(finished_at: nil).count,
          active_data_flow_jobs: SolidQueue::Job.where(
            queue_name: "active_data_flow",
            finished_at: nil
          ).count,
          claimed_jobs: SolidQueue::ClaimedExecution.count,
          failed_jobs: SolidQueue::FailedExecution.count,
          scheduled_jobs: SolidQueue::ScheduledExecution.count,
          recurring_tasks: SolidQueue::RecurringTask.count
        }
      rescue StandardError => e
        { error: e.message }
      end

      def check_database
        ActiveDataFlow::DataFlow.count
        { status: :healthy, message: "Database connection OK" }
      rescue StandardError => e
        { status: :critical, message: e.message }
      end

      def check_queue
        adapter = ActiveJob::Base.queue_adapter.class.name

        if defined?(SolidQueue)
          failed = SolidQueue::FailedExecution.count
          if failed > 100
            { status: :degraded, message: "#{failed} failed jobs", adapter: adapter }
          else
            { status: :healthy, message: "Queue healthy", adapter: adapter, failed_jobs: failed }
          end
        else
          { status: :healthy, message: "Queue adapter: #{adapter}", adapter: adapter }
        end
      rescue StandardError => e
        { status: :degraded, message: e.message }
      end

      def check_flows
        active = ActiveDataFlow::DataFlow.active.count
        enabled = ActiveDataFlow::DataFlow.active.select(&:enabled?).count

        if enabled.zero? && active.positive?
          { status: :degraded, message: "No enabled flows", active: active, enabled: enabled }
        else
          { status: :healthy, message: "#{enabled}/#{active} flows enabled", active: active, enabled: enabled }
        end
      rescue StandardError => e
        { status: :critical, message: e.message }
      end

      def check_error_rate
        stats = ErrorHandling::ErrorTracker.statistics
        error_count = stats[:total_24h]

        if error_count > 100
          { status: :degraded, message: "High error rate", errors_24h: error_count }
        elsif error_count > 500
          { status: :critical, message: "Critical error rate", errors_24h: error_count }
        else
          { status: :healthy, message: "Error rate normal", errors_24h: error_count }
        end
      rescue StandardError => e
        { status: :degraded, message: e.message }
      end
    end
  end
end
