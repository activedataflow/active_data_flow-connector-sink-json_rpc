# frozen_string_literal: true

module ActiveDataFlow
  # Provides bulk enqueuing operations for data flows.
  #
  # This module leverages ActiveJob's `perform_all_later` (Rails 7.1+) for
  # efficient batch job creation, reducing database round trips.
  #
  # @example Enqueue all active flows
  #   ActiveDataFlow::BulkEnqueue.enqueue_all_active
  #
  # @example Enqueue flows by group
  #   ActiveDataFlow::BulkEnqueue.enqueue_group("exports")
  #
  # @example Enqueue specific flows
  #   ActiveDataFlow::BulkEnqueue.enqueue_flows(["user_sync", "order_export"])
  #
  class BulkEnqueue
    class << self
      # Enqueues all active and enabled flows.
      #
      # @param queue [Symbol, nil] Override queue for all jobs
      # @return [Hash] Result with :enqueued count and :jobs
      def enqueue_all_active(queue: nil)
        flows = ActiveDataFlow::DataFlow.active.select(&:enabled?)
        enqueue_flows_collection(flows, queue: queue)
      end

      # Enqueues all flows in a specific concurrency group.
      #
      # @param group_name [String] The concurrency group name
      # @param queue [Symbol, nil] Override queue for all jobs
      # @return [Hash] Result with :enqueued count and :jobs
      def enqueue_group(group_name, queue: nil)
        flows = ActiveDataFlow::DataFlow.active.select do |flow|
          flow.enabled? && flow.concurrency_group == group_name
        end
        enqueue_flows_collection(flows, queue: queue, group: group_name)
      end

      # Enqueues specific flows by name.
      #
      # @param names [Array<String>] Flow names to enqueue
      # @param queue [Symbol, nil] Override queue for all jobs
      # @return [Hash] Result with :enqueued count, :jobs, and :not_found
      def enqueue_flows(names, queue: nil)
        flows = []
        not_found = []

        names.each do |name|
          flow = ActiveDataFlow::DataFlow.find_by(name: name)
          if flow&.enabled?
            flows << flow
          elsif flow
            Rails.logger.info "[BulkEnqueue] Skipping disabled flow: #{name}"
          else
            not_found << name
          end
        end

        result = enqueue_flows_collection(flows, queue: queue)
        result[:not_found] = not_found
        result
      end

      # Enqueues flows for execution at a specific time.
      #
      # @param flows [Array<DataFlow>] Flows to enqueue
      # @param run_at [Time] When to execute
      # @param queue [Symbol, nil] Override queue
      # @return [Hash] Result with :scheduled count
      def schedule_flows(flows, run_at:, queue: nil)
        jobs = flows.map do |flow|
          next unless flow.enabled?

          job_options = { wait_until: run_at }
          job_options[:queue] = queue if queue

          ActiveDataFlow::DataFlowJob.set(**job_options).perform_later(flow.id)
        end.compact

        {
          scheduled: jobs.size,
          run_at: run_at,
          jobs: jobs
        }
      end

      # Enqueues flows with staggered start times to avoid thundering herd.
      #
      # @param flows [Array<DataFlow>] Flows to enqueue
      # @param interval [ActiveSupport::Duration] Time between each flow start
      # @param queue [Symbol, nil] Override queue
      # @return [Hash] Result with :scheduled count and :schedule
      def enqueue_staggered(flows, interval: 10.seconds, queue: nil)
        schedule = []
        jobs = []

        flows.each_with_index do |flow, index|
          next unless flow.enabled?

          delay = interval * index
          run_at = Time.current + delay

          job_options = { wait: delay }
          job_options[:queue] = queue if queue

          job = ActiveDataFlow::DataFlowJob.set(**job_options).perform_later(flow.id)
          jobs << job
          schedule << { flow: flow.name, run_at: run_at, job_id: job.job_id }
        end

        {
          scheduled: jobs.size,
          interval: interval,
          schedule: schedule,
          jobs: jobs
        }
      end

      private

      def enqueue_flows_collection(flows, queue: nil, group: nil)
        return { enqueued: 0, jobs: [], group: group } if flows.empty?

        # Use perform_all_later if available (Rails 7.1+)
        if ActiveDataFlow::DataFlowJob.respond_to?(:perform_all_later)
          enqueue_bulk(flows, queue: queue, group: group)
        else
          enqueue_sequential(flows, queue: queue, group: group)
        end
      end

      def enqueue_bulk(flows, queue: nil, group: nil)
        # Build job instances
        jobs = flows.map do |flow|
          job = ActiveDataFlow::DataFlowJob.new(flow.id)
          job.queue_name = queue.to_s if queue
          job
        end

        # Enqueue all at once
        ActiveDataFlow::DataFlowJob.perform_all_later(jobs)

        # Check which jobs were successfully enqueued
        enqueued = jobs.select(&:successfully_enqueued?)

        {
          enqueued: enqueued.size,
          total: flows.size,
          jobs: enqueued,
          group: group,
          bulk: true
        }
      end

      def enqueue_sequential(flows, queue: nil, group: nil)
        jobs = flows.map do |flow|
          job_options = {}
          job_options[:queue] = queue if queue

          ActiveDataFlow::DataFlowJob.set(**job_options).perform_later(flow.id)
        end

        {
          enqueued: jobs.size,
          total: flows.size,
          jobs: jobs,
          group: group,
          bulk: false
        }
      end
    end
  end
end
