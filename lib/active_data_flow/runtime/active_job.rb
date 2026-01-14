# frozen_string_literal: true

module ActiveDataFlow
  module Runtime
    # ActiveJob-based runtime for executing data flows via Rails job infrastructure.
    #
    # This runtime integrates with Rails ActiveJob and SolidQueue (Rails 8+ default)
    # to provide robust, database-backed job scheduling with built-in retry handling,
    # concurrency controls, and observability.
    #
    # @example Basic usage
    #   runtime = ActiveDataFlow::Runtime::ActiveJob.new(
    #     queue: :data_flows,
    #     interval: 5.minutes,
    #     batch_size: 100
    #   )
    #
    # @example With priority
    #   runtime = ActiveDataFlow::Runtime::ActiveJob.new(
    #     queue: :critical,
    #     priority: 1,
    #     interval: 60
    #   )
    #
    # @example With concurrency controls (SolidQueue)
    #   runtime = ActiveDataFlow::Runtime::ActiveJob.new(
    #     queue: :data_flows,
    #     concurrency_limit: 1,           # Max concurrent executions of this flow
    #     concurrency_group: "exports",   # Group flows for shared concurrency limit
    #     concurrency_group_limit: 3      # Max concurrent across the group
    #   )
    #
    # @example With job continuations (Rails 8.1+)
    #   runtime = ActiveDataFlow::Runtime::ActiveJob.new(
    #     queue: :data_flows,
    #     use_continuations: true,        # Enable resumable batch processing
    #     max_resumptions: 10             # Max times job can be resumed (nil = unlimited)
    #   )
    #
    class ActiveJob < Base
      attr_reader :queue, :priority, :concurrency_limit, :concurrency_group, :concurrency_group_limit,
                  :use_continuations, :max_resumptions

      # @param queue [Symbol] The queue to use for jobs (default: :active_data_flow)
      # @param priority [Integer, nil] Job priority (lower = higher priority, SolidQueue only)
      # @param batch_size [Integer] Records to process per execution (default: 100)
      # @param enabled [Boolean] Whether the runtime is active (default: true)
      # @param interval [Integer] Seconds between recurring executions (default: 3600)
      # @param concurrency_limit [Integer, nil] Max concurrent executions of this flow (default: 1)
      # @param concurrency_group [String, nil] Group name for shared concurrency limits
      # @param concurrency_group_limit [Integer, nil] Max concurrent across the group
      # @param use_continuations [Boolean] Enable ActiveJob::Continuable for resumable processing (default: false)
      # @param max_resumptions [Integer, nil] Max times a job can be resumed (nil = unlimited)
      def initialize(
        queue: :active_data_flow,
        priority: nil,
        batch_size: 100,
        enabled: true,
        interval: 3600,
        concurrency_limit: 1,
        concurrency_group: nil,
        concurrency_group_limit: nil,
        use_continuations: false,
        max_resumptions: nil,
        **options
      )
        super(batch_size: batch_size, enabled: enabled, interval: interval, **options)
        @queue = queue.to_sym
        @priority = priority
        @concurrency_limit = concurrency_limit
        @concurrency_group = concurrency_group
        @concurrency_group_limit = concurrency_group_limit
        @use_continuations = use_continuations
        @max_resumptions = max_resumptions
      end

      # Check if ActiveJob::Continuable is available (Rails 8.1+)
      #
      # @return [Boolean]
      def self.continuations_available?
        defined?(::ActiveJob::Continuable)
      end

      # Check if this runtime should use continuations
      #
      # @return [Boolean]
      def continuations_enabled?
        use_continuations && self.class.continuations_available?
      end

      # Execute a data flow immediately via ActiveJob.
      #
      # @param data_flow [ActiveDataFlow::DataFlow] The flow to execute
      # @return [ActiveJob::Base, nil] The enqueued job, or nil if disabled
      def execute(data_flow)
        return unless enabled?

        job = enqueue_job(data_flow)
        Rails.logger.info "[ActiveDataFlow::Runtime::ActiveJob] Enqueued job #{job.job_id} for flow: #{data_flow.name}"
        job
      end

      # Schedule a data flow for execution at a specific time.
      #
      # @param data_flow [ActiveDataFlow::DataFlow] The flow to execute
      # @param run_at [Time] When to execute the flow
      # @return [ActiveJob::Base, nil] The enqueued job, or nil if disabled
      def execute_at(data_flow, run_at)
        return unless enabled?

        job = enqueue_job(data_flow, wait_until: run_at)
        Rails.logger.info "[ActiveDataFlow::Runtime::ActiveJob] Scheduled job #{job.job_id} for flow: #{data_flow.name} at #{run_at}"
        job
      end

      # Schedule the next recurring execution based on interval.
      #
      # @param data_flow [ActiveDataFlow::DataFlow] The flow to schedule
      # @param from_time [Time] Base time for calculation (default: now)
      # @return [ActiveJob::Base, nil] The enqueued job, or nil if disabled/no interval
      def schedule_next(data_flow, from_time: Time.current)
        return unless enabled?
        return unless interval.to_i > 0

        next_run = from_time + interval.seconds
        execute_at(data_flow, next_run)
      end

      # Serialize runtime configuration to JSON.
      #
      # @return [Hash] JSON-serializable configuration
      def as_json(*_args)
        super.merge(
          "queue" => queue.to_s,
          "priority" => priority,
          "concurrency_limit" => concurrency_limit,
          "concurrency_group" => concurrency_group,
          "concurrency_group_limit" => concurrency_group_limit,
          "use_continuations" => use_continuations,
          "max_resumptions" => max_resumptions
        ).compact
      end

      # Deserialize runtime from JSON data.
      #
      # @param data [Hash] Serialized runtime data
      # @return [ActiveDataFlow::Runtime::ActiveJob] Rehydrated runtime instance
      def self.from_json(data)
        data = data.symbolize_keys
        data.delete(:class_name)
        data[:queue] = data[:queue]&.to_sym || :active_data_flow
        data[:concurrency_limit] = data[:concurrency_limit]&.to_i if data[:concurrency_limit]
        data[:concurrency_group_limit] = data[:concurrency_group_limit]&.to_i if data[:concurrency_group_limit]
        data[:max_resumptions] = data[:max_resumptions]&.to_i if data[:max_resumptions]
        data[:use_continuations] = data[:use_continuations] == true if data.key?(:use_continuations)
        new(**data)
      end

      # Returns the concurrency key for this runtime.
      # Used by DataFlowJob for SolidQueue's limits_concurrency.
      #
      # @param data_flow [ActiveDataFlow::DataFlow] The flow
      # @return [String] The concurrency key
      def concurrency_key_for(data_flow)
        if concurrency_group.present?
          "active_data_flow:group:#{concurrency_group}"
        else
          "active_data_flow:flow:#{data_flow.name}"
        end
      end

      # Returns the effective concurrency limit.
      #
      # @return [Integer] The limit to apply
      def effective_concurrency_limit
        if concurrency_group.present? && concurrency_group_limit
          concurrency_group_limit
        else
          concurrency_limit || 1
        end
      end

      private

      def enqueue_job(data_flow, wait_until: nil)
        job_options = { queue: queue }
        job_options[:priority] = priority if priority
        job_options[:wait_until] = wait_until if wait_until

        job_class = select_job_class
        job_class
          .set(**job_options)
          .perform_later(data_flow.id)
      end

      def select_job_class
        if continuations_enabled?
          ActiveDataFlow::ContinuableDataFlowJob
        else
          ActiveDataFlow::DataFlowJob
        end
      end
    end
  end
end
