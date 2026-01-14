# frozen_string_literal: true

module ActiveDataFlow
  class DataFlowJob < ApplicationJob
    queue_as :active_data_flow

    # === Retry Configuration ===
    # Transient errors: retry with backoff
    retry_on ActiveRecord::Deadlocked, wait: 5.seconds, attempts: 3
    retry_on ActiveRecord::LockWaitTimeout, wait: 5.seconds, attempts: 3
    retry_on Net::OpenTimeout, wait: :polynomially_longer, attempts: 10
    retry_on Net::ReadTimeout, wait: :polynomially_longer, attempts: 10
    retry_on Errno::ECONNREFUSED, wait: :polynomially_longer, attempts: 5
    retry_on Errno::ECONNRESET, wait: :polynomially_longer, attempts: 5

    # Default retry for other errors
    retry_on StandardError, wait: :polynomially_longer, attempts: 5

    # === Discard Configuration ===
    # Permanent errors: don't retry
    discard_on ActiveJob::DeserializationError
    discard_on ActiveRecord::RecordNotFound

    # === Callbacks ===
    before_perform :emit_flow_started
    after_perform :emit_flow_completed

    around_perform :track_execution_time

    after_discard do |job, error|
      handle_discard(job, error)
    end

    # === Concurrency Control (SolidQueue) ===
    if respond_to?(:limits_concurrency)
      limits_concurrency(
        key: ->(data_flow_id, **) { concurrency_key_for(data_flow_id) },
        to: ->(data_flow_id, **) { concurrency_limit_for(data_flow_id) }
      )
    end

    class << self
      def concurrency_key_for(data_flow_id)
        flow = resolve_flow_for_concurrency(data_flow_id)
        return "active_data_flow:default" unless flow

        flow.concurrency_key
      end

      def concurrency_limit_for(data_flow_id)
        flow = resolve_flow_for_concurrency(data_flow_id)
        return 1 unless flow

        flow.effective_concurrency_limit
      end

      private

      def resolve_flow_for_concurrency(data_flow_id)
        case data_flow_id
        when Integer
          ActiveDataFlow::DataFlow.find_by(id: data_flow_id)
        when String
          if data_flow_id.start_with?("gid://")
            GlobalID::Locator.locate(data_flow_id)
          else
            ActiveDataFlow::DataFlow.find_by(id: data_flow_id) ||
              ActiveDataFlow::DataFlow.find_by(name: data_flow_id)
          end
        else
          ActiveDataFlow::DataFlow.find_by(id: data_flow_id)
        end
      rescue StandardError
        nil
      end

      def handle_discard(job, error)
        Rails.logger.error "[DataFlowJob] Discarded: #{error.class.name}: #{error.message}"

        data_flow = job.resolve_data_flow_for_callbacks(job.arguments.first)
        return unless data_flow

        # Track the error
        ErrorHandling::ErrorTracker.record(
          flow: data_flow,
          error: error,
          attempt: job.executions
        )

        # Emit instrumentation event
        Instrumentation.flow_discarded(
          flow: data_flow,
          run: nil,
          error: error,
          job: job
        )

        # Run failure callbacks
        job.send(:run_failure_callbacks, data_flow, nil, error)

        # Update flow status
        data_flow.update(last_error: "Discarded: #{error.message}")
      rescue StandardError => e
        Rails.logger.error "[DataFlowJob] Error in discard handler: #{e.message}"
      end
    end

    # @param data_flow_id [Integer, String, GlobalID] The flow to execute
    # @param run_id [Integer, nil] Optional existing run record ID
    def perform(data_flow_id, run_id: nil)
      @data_flow = resolve_data_flow(data_flow_id)

      unless @data_flow
        Rails.logger.warn "[DataFlowJob] Flow not found: #{data_flow_id}"
        return
      end

      unless @data_flow.enabled?
        Rails.logger.info "[DataFlowJob] Flow disabled: #{@data_flow.name}"
        return
      end

      @data_flow_run = find_or_create_run(@data_flow, run_id)
      Rails.logger.info "[DataFlowJob] Executing flow: #{@data_flow.name}, run: #{@data_flow_run.id}"

      result = execute_with_error_handling

      case result
      when Dry::Monads::Result::Success
        handle_success
      when Dry::Monads::Result::Failure
        handle_failure(result)
      end

      result
    end

    def resolve_data_flow_for_callbacks(data_flow_id)
      resolve_data_flow(data_flow_id)
    end

    private

    def execute_with_error_handling
      ActiveDataFlow::Runtime::FlowExecutor.execute(@data_flow_run)
    rescue StandardError => e
      # Track the error
      track_error(e)

      # Check if we should retry or give up
      if should_retry?(e)
        emit_retry_event(e)
        raise # Re-raise to trigger ActiveJob retry
      else
        emit_failure_event(e)
        Dry::Monads::Result::Failure[:execution_error, { message: e.message, exception_class: e.class.name }]
      end
    end

    def should_retry?(error)
      return false if executions >= max_attempts_for(error)

      ErrorHandling.retriable?(error)
    end

    def max_attempts_for(error)
      # Check flow-specific policy first
      if @data_flow.respond_to?(:retry_policy)
        policy = @data_flow.retry_policy
        return policy[:max_attempts] if policy[:max_attempts]
      end

      # Fall back to global config
      ErrorHandling.configuration.max_attempts
    end

    def track_error(error)
      ErrorHandling::ErrorTracker.record(
        flow: @data_flow,
        error: error,
        run: @data_flow_run,
        attempt: executions
      )
    end

    def emit_flow_started
      return unless @data_flow && @data_flow_run

      Instrumentation.flow_started(
        flow: @data_flow,
        run: @data_flow_run,
        job: self
      )
    end

    def emit_flow_completed
      return unless @data_flow && @data_flow_run && @execution_successful

      Instrumentation.flow_completed(
        flow: @data_flow,
        run: @data_flow_run,
        job: self,
        duration: @execution_duration,
        records_processed: @data_flow_run.records_processed
      )

      # Record metrics
      Metrics.record(
        event_type: :completed,
        flow_name: @data_flow.name,
        duration: @execution_duration,
        records_processed: @data_flow_run.records_processed
      )
    end

    def emit_retry_event(error)
      wait_time = ErrorHandling.configuration.wait_time_for(executions)

      Instrumentation.flow_retried(
        flow: @data_flow,
        run: @data_flow_run,
        error: error,
        attempt: executions,
        wait: wait_time,
        job: self
      )
    end

    def emit_failure_event(error)
      Instrumentation.flow_failed(
        flow: @data_flow,
        run: @data_flow_run,
        error: error,
        attempt: executions,
        job: self
      )

      Metrics.record(
        event_type: :failed,
        flow_name: @data_flow.name,
        error_class: error.class.name
      )
    end

    def track_execution_time
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      @execution_successful = false

      yield

      @execution_successful = true
    ensure
      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      @execution_duration = ((end_time - start_time) * 1000).round(2) # milliseconds
    end

    def resolve_data_flow(data_flow_id)
      case data_flow_id
      when GlobalID
        GlobalID::Locator.locate(data_flow_id)
      when String
        if data_flow_id.start_with?("gid://")
          GlobalID::Locator.locate(data_flow_id)
        else
          ActiveDataFlow::DataFlow.find_by(id: data_flow_id) ||
            ActiveDataFlow::DataFlow.find_by(name: data_flow_id)
        end
      when Integer
        ActiveDataFlow::DataFlow.find_by(id: data_flow_id)
      else
        ActiveDataFlow::DataFlow.find_by(id: data_flow_id)
      end
    end

    def find_or_create_run(data_flow, run_id)
      if run_id
        data_flow.data_flow_runs.find(run_id)
      else
        data_flow.data_flow_runs.create!(
          status: "pending",
          run_after: Time.current
        )
      end
    end

    def handle_success
      Rails.logger.info "[DataFlowJob] Flow completed: #{@data_flow.name}"

      run_completion_callbacks(@data_flow, @data_flow_run)
      schedule_next_if_recurring(@data_flow)
    end

    def handle_failure(result)
      Rails.logger.error "[DataFlowJob] Flow failed: #{@data_flow.name}"

      error = extract_error_from_result(result)
      track_error(error)
      emit_failure_event(error)
      run_failure_callbacks(@data_flow, @data_flow_run, error)
    end

    def extract_error_from_result(result)
      case result
      when Dry::Monads::Result::Failure
        failure_data = result.failure
        if failure_data.is_a?(Array) && failure_data[1].is_a?(Hash)
          StandardError.new(failure_data[1][:message] || failure_data[0].to_s)
        else
          StandardError.new(failure_data.to_s)
        end
      else
        StandardError.new("Unknown error")
      end
    end

    def run_completion_callbacks(data_flow, run)
      return unless data_flow.respond_to?(:run_after_complete_callbacks)

      begin
        flow_instance = cast_to_flow_class(data_flow)
        flow_instance.run_after_complete_callbacks(run) if flow_instance.respond_to?(:run_after_complete_callbacks)
      rescue StandardError => e
        Rails.logger.error "[DataFlowJob] Completion callback error: #{e.message}"
      end
    end

    def run_failure_callbacks(data_flow, run, error)
      return unless data_flow&.respond_to?(:run_after_failure_callbacks)

      begin
        flow_instance = cast_to_flow_class(data_flow)
        flow_instance.run_after_failure_callbacks(run, error) if flow_instance.respond_to?(:run_after_failure_callbacks)
      rescue StandardError => e
        Rails.logger.error "[DataFlowJob] Failure callback error: #{e.message}"
      end
    end

    def cast_to_flow_class(data_flow)
      return data_flow unless data_flow.respond_to?(:flow_class)

      begin
        flow_class = data_flow.flow_class
        if flow_class != data_flow.class && data_flow.respond_to?(:becomes)
          data_flow.becomes(flow_class)
        else
          data_flow
        end
      rescue StandardError
        data_flow
      end
    end

    def schedule_next_if_recurring(data_flow)
      runtime = data_flow.parsed_runtime
      return unless runtime
      return unless runtime["class_name"] == "ActiveDataFlow::Runtime::ActiveJob"
      return unless runtime["interval"].to_i > 0

      interval = runtime["interval"].to_i
      queue = runtime["queue"]&.to_sym || :active_data_flow
      priority = runtime["priority"]

      job_class = runtime["use_continuations"] ? ContinuableDataFlowJob : self.class
      job_class.set(queue: queue, priority: priority, wait: interval.seconds)
               .perform_later(data_flow.id)

      Rails.logger.info "[DataFlowJob] Scheduled next run in #{interval}s for: #{data_flow.name}"
    end
  end
end
