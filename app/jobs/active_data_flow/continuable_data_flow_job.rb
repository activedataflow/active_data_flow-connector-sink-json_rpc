# frozen_string_literal: true

module ActiveDataFlow
  # A data flow job that uses ActiveJob::Continuable for resumable batch processing.
  #
  # This job leverages Rails 8.1+ ActiveJob continuations to:
  # - Process large datasets in batches without losing progress
  # - Resume from the last processed record after interruption
  # - Track progress via cursors that survive job restarts
  #
  # @example Basic usage
  #   ContinuableDataFlowJob.perform_later(flow.id)
  #
  # @example With max resumptions
  #   ContinuableDataFlowJob.set(max_resumptions: 10).perform_later(flow.id)
  #
  # @note Requires Rails 8.1+ with ActiveJob::Continuable support
  #
  class ContinuableDataFlowJob < ApplicationJob
    queue_as :active_data_flow

    # Include Continuable if available (Rails 8.1+)
    if defined?(ActiveJob::Continuable)
      include ActiveJob::Continuable

      # Configure continuation behavior
      # max_resumptions: nil means unlimited
      # resume_options: how long to wait before resuming
      self.max_resumptions = nil
      self.resume_options = { wait: 5.seconds }
    end

    # Retry configuration
    retry_on ActiveRecord::Deadlocked, wait: 5.seconds, attempts: 3
    discard_on ActiveJob::DeserializationError

    # Concurrency control via SolidQueue (if available)
    if respond_to?(:limits_concurrency)
      limits_concurrency(
        key: ->(data_flow_id, **) { DataFlowJob.concurrency_key_for(data_flow_id) },
        to: ->(data_flow_id, **) { DataFlowJob.concurrency_limit_for(data_flow_id) }
      )
    end

    # @param data_flow_id [Integer, String] The flow to execute
    # @param run_id [Integer, nil] Optional existing run record ID
    def perform(data_flow_id, run_id: nil)
      @data_flow = resolve_data_flow(data_flow_id)

      unless @data_flow
        Rails.logger.warn "[ContinuableDataFlowJob] Flow not found: #{data_flow_id}"
        return
      end

      unless @data_flow.enabled?
        Rails.logger.info "[ContinuableDataFlowJob] Flow disabled: #{@data_flow.name}"
        return
      end

      @data_flow_run = find_or_create_run(@data_flow, run_id)

      if continuable?
        execute_with_continuations
      else
        execute_without_continuations
      end
    end

    private

    def continuable?
      defined?(ActiveJob::Continuable) && self.class.included_modules.include?(ActiveJob::Continuable)
    end

    def execute_with_continuations
      Rails.logger.info "[ContinuableDataFlowJob] Starting continuable execution: #{@data_flow.name}"

      step :prepare do
        prepare_flow
      end

      step :process_batches do |step|
        process_batches_with_cursor(step)
      end

      step :finalize do
        finalize_flow
      end
    end

    def execute_without_continuations
      Rails.logger.info "[ContinuableDataFlowJob] Starting standard execution: #{@data_flow.name}"

      # Fall back to standard FlowExecutor
      result = ActiveDataFlow::Runtime::FlowExecutor.execute(@data_flow_run)

      case result
      when Dry::Monads::Result::Success
        run_completion_callbacks
        schedule_next_if_recurring
      when Dry::Monads::Result::Failure
        run_failure_callbacks(extract_error(result))
      end

      result
    end

    # Step 1: Prepare the flow for execution
    def prepare_flow
      Rails.logger.info "[ContinuableDataFlowJob] Preparing flow: #{@data_flow.name}"

      @data_flow.mark_run_started!(@data_flow_run)

      # Rehydrate connectors
      @source = rehydrate_connector(@data_flow.send(:parsed_source))
      @sink = rehydrate_connector(@data_flow.send(:parsed_sink))
      @runtime = rehydrate_runtime(@data_flow.send(:parsed_runtime))

      # Update run with preparation timestamp
      update_run_progress(step: "prepare", status: "completed")
    end

    # Step 2: Process batches with cursor tracking
    def process_batches_with_cursor(step)
      cursor = step.cursor
      batch_size = @runtime&.batch_size || 100
      total_processed = 0

      Rails.logger.info "[ContinuableDataFlowJob] Processing batches from cursor: #{cursor.inspect}"

      loop do
        # Fetch next batch from source
        records = fetch_batch(cursor, batch_size)
        break if records.empty?

        # Process each record
        records.each do |record|
          transformed = @runtime ? @runtime.transform(record) : record
          @sink.write(transformed)
          total_processed += 1

          # Track the last processed ID
          cursor = extract_record_id(record)
        end

        # Advance the cursor checkpoint
        step.advance!(from: cursor)

        # Update run progress
        update_run_progress(
          step: "process_batches",
          cursor: cursor,
          records_processed: total_processed
        )

        Rails.logger.info "[ContinuableDataFlowJob] Processed batch, cursor: #{cursor}, total: #{total_processed}"

        # Break if we got fewer records than batch_size (end of data)
        break if records.size < batch_size
      end

      Rails.logger.info "[ContinuableDataFlowJob] Batch processing complete. Total: #{total_processed}"
      total_processed
    end

    # Step 3: Finalize the flow
    def finalize_flow
      Rails.logger.info "[ContinuableDataFlowJob] Finalizing flow: #{@data_flow.name}"

      @data_flow.mark_run_completed!(@data_flow_run)

      # Run completion callbacks
      run_completion_callbacks

      # Schedule next run if recurring
      schedule_next_if_recurring

      update_run_progress(step: "finalize", status: "completed")
    end

    def fetch_batch(cursor, batch_size)
      if @source.respond_to?(:fetch_batch)
        @source.fetch_batch(after: cursor, limit: batch_size)
      elsif @source.respond_to?(:each)
        # Collect records from enumerable source
        records = []
        @source.each(batch_size: batch_size, start_id: cursor) do |record|
          records << record
          break if records.size >= batch_size
        end
        records
      else
        Rails.logger.warn "[ContinuableDataFlowJob] Source doesn't support batch fetching"
        []
      end
    end

    def extract_record_id(record)
      case record
      when Hash
        record["id"] || record[:id]
      when ActiveRecord::Base
        record.id
      else
        record.respond_to?(:id) ? record.id : nil
      end
    end

    def rehydrate_connector(data)
      return nil unless data

      klass_name = data["class_name"]
      return nil unless klass_name

      klass = klass_name.constantize
      klass.from_json(data)
    rescue NameError => e
      Rails.logger.error "[ContinuableDataFlowJob] Failed to load connector: #{e.message}"
      nil
    end

    def rehydrate_runtime(data)
      return ActiveDataFlow::Runtime::Base.new unless data

      klass_name = data["class_name"]
      return ActiveDataFlow::Runtime::Base.new unless klass_name

      klass = klass_name.constantize
      klass.from_json(data)
    rescue NameError => e
      Rails.logger.error "[ContinuableDataFlowJob] Failed to load runtime: #{e.message}"
      ActiveDataFlow::Runtime::Base.new
    end

    def update_run_progress(step:, status: nil, cursor: nil, records_processed: nil)
      return unless @data_flow_run

      updates = { updated_at: Time.current }
      updates[:status] = status if status

      # Store progress in metadata (if column exists) or use existing cursor columns
      if @data_flow_run.respond_to?(:metadata=)
        metadata = (@data_flow_run.metadata || {}).merge(
          "current_step" => step,
          "cursor" => cursor,
          "records_processed" => records_processed,
          "resumptions" => resumptions
        ).compact
        updates[:metadata] = metadata
      end

      # Update cursor columns if they exist
      updates[:last_id] = cursor if cursor && @data_flow_run.respond_to?(:last_id=)

      @data_flow_run.update(updates)
    rescue StandardError => e
      Rails.logger.warn "[ContinuableDataFlowJob] Failed to update progress: #{e.message}"
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

    def run_completion_callbacks
      return unless @data_flow.respond_to?(:run_after_complete_callbacks)

      begin
        flow_instance = cast_to_flow_class(@data_flow)
        flow_instance.run_after_complete_callbacks(@data_flow_run) if flow_instance.respond_to?(:run_after_complete_callbacks)
      rescue StandardError => e
        Rails.logger.error "[ContinuableDataFlowJob] Completion callback error: #{e.message}"
      end
    end

    def run_failure_callbacks(error)
      return unless @data_flow.respond_to?(:run_after_failure_callbacks)

      begin
        flow_instance = cast_to_flow_class(@data_flow)
        flow_instance.run_after_failure_callbacks(@data_flow_run, error) if flow_instance.respond_to?(:run_after_failure_callbacks)
      rescue StandardError => e
        Rails.logger.error "[ContinuableDataFlowJob] Failure callback error: #{e.message}"
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

    def extract_error(result)
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

    def schedule_next_if_recurring
      runtime = @data_flow.parsed_runtime
      return unless runtime
      return unless runtime["class_name"] == "ActiveDataFlow::Runtime::ActiveJob"
      return unless runtime["interval"].to_i > 0

      interval = runtime["interval"].to_i
      queue = runtime["queue"]&.to_sym || :active_data_flow
      priority = runtime["priority"]

      # Use ContinuableDataFlowJob for next run if continuations enabled
      job_class = runtime["use_continuations"] ? self.class : DataFlowJob
      job_class.set(queue: queue, priority: priority, wait: interval.seconds)
               .perform_later(@data_flow.id)

      Rails.logger.info "[ContinuableDataFlowJob] Scheduled next run in #{interval}s"
    end
  end
end
