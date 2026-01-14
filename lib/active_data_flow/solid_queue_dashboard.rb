# frozen_string_literal: true

module ActiveDataFlow
  # Provides dashboard helpers for monitoring SolidQueue jobs related to ActiveDataFlow.
  #
  # This module offers utilities for building admin dashboards, monitoring pages,
  # and operational tooling around data flow jobs.
  #
  # @example Get job overview
  #   overview = ActiveDataFlow::SolidQueueDashboard.overview
  #   puts "Pending: #{overview[:pending_jobs]}, Failed: #{overview[:failed_jobs]}"
  #
  # @example Get jobs for a specific flow
  #   jobs = ActiveDataFlow::SolidQueueDashboard.jobs_for_flow("user_sync")
  #
  module SolidQueueDashboard
    class << self
      # Check if SolidQueue is available
      #
      # @return [Boolean]
      def available?
        defined?(SolidQueue) && SolidQueue::Job.respond_to?(:all)
      rescue StandardError
        false
      end

      # Get an overview of all ActiveDataFlow jobs in SolidQueue
      #
      # @return [Hash] Job counts and status overview
      def overview
        return unavailable_response unless available?

        {
          available: true,
          timestamp: Time.current.iso8601,
          pending_jobs: pending_jobs_count,
          claimed_jobs: claimed_jobs_count,
          failed_jobs: failed_jobs_count,
          scheduled_jobs: scheduled_jobs_count,
          recurring_tasks: recurring_tasks_count,
          jobs_by_queue: jobs_by_queue,
          jobs_by_status: jobs_by_status,
          recent_failures: recent_failures(limit: 5)
        }
      rescue StandardError => e
        { available: false, error: e.message }
      end

      # Get pending jobs for ActiveDataFlow
      #
      # @param limit [Integer] Maximum jobs to return
      # @return [Array<Hash>] Pending job details
      def pending_jobs(limit: 50)
        return [] unless available?

        SolidQueue::Job.where(finished_at: nil)
                       .where(class_name: data_flow_job_classes)
                       .order(scheduled_at: :asc)
                       .limit(limit)
                       .map { |job| format_job(job) }
      end

      # Get failed jobs for ActiveDataFlow
      #
      # @param limit [Integer] Maximum jobs to return
      # @return [Array<Hash>] Failed job details
      def failed_jobs(limit: 50)
        return [] unless available?

        SolidQueue::FailedExecution.includes(:job)
                                   .joins(:job)
                                   .where(solid_queue_jobs: { class_name: data_flow_job_classes })
                                   .order(created_at: :desc)
                                   .limit(limit)
                                   .map { |exec| format_failed_execution(exec) }
      end

      # Get jobs for a specific flow
      #
      # @param flow_name [String] The flow name or ID
      # @param status [Symbol, nil] Filter by status (:pending, :claimed, :failed, :completed)
      # @param limit [Integer] Maximum jobs to return
      # @return [Array<Hash>] Job details
      def jobs_for_flow(flow_name, status: nil, limit: 50)
        return [] unless available?

        flow = ActiveDataFlow::DataFlow.find_by(name: flow_name) ||
               ActiveDataFlow::DataFlow.find_by(id: flow_name)
        return [] unless flow

        jobs = SolidQueue::Job.where(class_name: data_flow_job_classes)

        # Filter by flow ID in arguments
        jobs = jobs.where("arguments LIKE ?", "%#{flow.id}%")

        jobs = apply_status_filter(jobs, status)
        jobs.order(created_at: :desc).limit(limit).map { |job| format_job(job) }
      end

      # Retry a failed job
      #
      # @param job_id [Integer] The SolidQueue job ID
      # @return [Boolean] Success status
      def retry_job(job_id)
        return false unless available?

        failed = SolidQueue::FailedExecution.find_by(job_id: job_id)
        return false unless failed

        failed.retry
        true
      rescue StandardError => e
        Rails.logger.error "[SolidQueueDashboard] Retry failed: #{e.message}"
        false
      end

      # Retry all failed ActiveDataFlow jobs
      #
      # @return [Integer] Number of jobs retried
      def retry_all_failed
        return 0 unless available?

        failed = SolidQueue::FailedExecution.joins(:job)
                                            .where(solid_queue_jobs: { class_name: data_flow_job_classes })

        count = 0
        failed.find_each do |exec|
          exec.retry
          count += 1
        rescue StandardError => e
          Rails.logger.error "[SolidQueueDashboard] Retry failed for job #{exec.job_id}: #{e.message}"
        end

        count
      end

      # Discard a failed job
      #
      # @param job_id [Integer] The SolidQueue job ID
      # @return [Boolean] Success status
      def discard_job(job_id)
        return false unless available?

        failed = SolidQueue::FailedExecution.find_by(job_id: job_id)
        return false unless failed

        failed.discard
        true
      rescue StandardError => e
        Rails.logger.error "[SolidQueueDashboard] Discard failed: #{e.message}"
        false
      end

      # Get recurring tasks for ActiveDataFlow
      #
      # @return [Array<Hash>] Recurring task details
      def recurring_tasks
        return [] unless available?
        return [] unless SolidQueue.const_defined?(:RecurringTask)

        SolidQueue::RecurringTask.where(class_name: data_flow_job_classes)
                                 .map { |task| format_recurring_task(task) }
      rescue StandardError
        []
      end

      # Get queue statistics
      #
      # @return [Hash] Statistics per queue
      def queue_statistics
        return {} unless available?

        queues = SolidQueue::Job.where(class_name: data_flow_job_classes)
                                .group(:queue_name)
                                .count

        queues.transform_values do |count|
          {
            total: count,
            pending: SolidQueue::Job.where(class_name: data_flow_job_classes, finished_at: nil)
                                    .count,
            completed_24h: SolidQueue::Job.where(class_name: data_flow_job_classes)
                                          .where("finished_at > ?", 24.hours.ago)
                                          .count
          }
        end
      rescue StandardError => e
        { error: e.message }
      end

      # Pause all ActiveDataFlow recurring tasks
      #
      # @return [Integer] Number of tasks paused
      def pause_all_recurring
        return 0 unless available?
        return 0 unless SolidQueue.const_defined?(:RecurringTask)

        count = 0
        SolidQueue::RecurringTask.where(class_name: data_flow_job_classes).find_each do |task|
          task.update(paused: true)
          count += 1
        rescue StandardError => e
          Rails.logger.error "[SolidQueueDashboard] Failed to pause task: #{e.message}"
        end

        count
      end

      # Resume all ActiveDataFlow recurring tasks
      #
      # @return [Integer] Number of tasks resumed
      def resume_all_recurring
        return 0 unless available?
        return 0 unless SolidQueue.const_defined?(:RecurringTask)

        count = 0
        SolidQueue::RecurringTask.where(class_name: data_flow_job_classes, paused: true).find_each do |task|
          task.update(paused: false)
          count += 1
        rescue StandardError => e
          Rails.logger.error "[SolidQueueDashboard] Failed to resume task: #{e.message}"
        end

        count
      end

      private

      def data_flow_job_classes
        %w[
          ActiveDataFlow::DataFlowJob
          ActiveDataFlow::ContinuableDataFlowJob
        ]
      end

      def unavailable_response
        { available: false, message: "SolidQueue is not available" }
      end

      def pending_jobs_count
        SolidQueue::Job.where(finished_at: nil)
                       .where(class_name: data_flow_job_classes)
                       .count
      end

      def claimed_jobs_count
        SolidQueue::ClaimedExecution.joins(:job)
                                    .where(solid_queue_jobs: { class_name: data_flow_job_classes })
                                    .count
      end

      def failed_jobs_count
        SolidQueue::FailedExecution.joins(:job)
                                   .where(solid_queue_jobs: { class_name: data_flow_job_classes })
                                   .count
      end

      def scheduled_jobs_count
        SolidQueue::ScheduledExecution.joins(:job)
                                      .where(solid_queue_jobs: { class_name: data_flow_job_classes })
                                      .count
      end

      def recurring_tasks_count
        return 0 unless SolidQueue.const_defined?(:RecurringTask)

        SolidQueue::RecurringTask.where(class_name: data_flow_job_classes).count
      rescue StandardError
        0
      end

      def jobs_by_queue
        SolidQueue::Job.where(class_name: data_flow_job_classes)
                       .where(finished_at: nil)
                       .group(:queue_name)
                       .count
      end

      def jobs_by_status
        {
          pending: SolidQueue::Job.where(class_name: data_flow_job_classes, finished_at: nil)
                                  .where.not(id: SolidQueue::ClaimedExecution.select(:job_id))
                                  .count,
          claimed: claimed_jobs_count,
          failed: failed_jobs_count,
          scheduled: scheduled_jobs_count
        }
      end

      def recent_failures(limit:)
        SolidQueue::FailedExecution.includes(:job)
                                   .joins(:job)
                                   .where(solid_queue_jobs: { class_name: data_flow_job_classes })
                                   .order(created_at: :desc)
                                   .limit(limit)
                                   .map { |exec| format_failed_execution(exec, brief: true) }
      end

      def apply_status_filter(jobs, status)
        case status
        when :pending
          jobs.where(finished_at: nil)
              .where.not(id: SolidQueue::ClaimedExecution.select(:job_id))
        when :claimed
          jobs.joins("INNER JOIN solid_queue_claimed_executions ON solid_queue_claimed_executions.job_id = solid_queue_jobs.id")
        when :failed
          jobs.joins("INNER JOIN solid_queue_failed_executions ON solid_queue_failed_executions.job_id = solid_queue_jobs.id")
        when :completed
          jobs.where.not(finished_at: nil)
        else
          jobs
        end
      end

      def format_job(job)
        {
          id: job.id,
          class_name: job.class_name,
          queue_name: job.queue_name,
          priority: job.priority,
          arguments: parse_arguments(job.arguments),
          scheduled_at: job.scheduled_at&.iso8601,
          created_at: job.created_at.iso8601,
          finished_at: job.finished_at&.iso8601,
          status: determine_job_status(job)
        }
      end

      def format_failed_execution(exec, brief: false)
        result = {
          job_id: exec.job_id,
          error_class: exec.exception_class,
          error_message: brief ? exec.message&.truncate(100) : exec.message,
          failed_at: exec.created_at.iso8601
        }

        unless brief
          result[:backtrace] = exec.backtrace&.first(10)
          result[:job] = format_job(exec.job) if exec.job
        end

        result
      end

      def format_recurring_task(task)
        {
          key: task.key,
          class_name: task.class_name,
          schedule: task.schedule,
          queue_name: task.queue_name,
          priority: task.priority,
          arguments: parse_arguments(task.arguments),
          paused: task.paused?,
          last_enqueued_at: task.last_enqueued_at&.iso8601
        }
      end

      def parse_arguments(arguments)
        return {} unless arguments

        JSON.parse(arguments)
      rescue JSON::ParserError
        { raw: arguments }
      end

      def determine_job_status(job)
        return :completed if job.finished_at.present?

        if SolidQueue::FailedExecution.exists?(job_id: job.id)
          :failed
        elsif SolidQueue::ClaimedExecution.exists?(job_id: job.id)
          :claimed
        elsif job.scheduled_at && job.scheduled_at > Time.current
          :scheduled
        else
          :pending
        end
      end
    end
  end
end
