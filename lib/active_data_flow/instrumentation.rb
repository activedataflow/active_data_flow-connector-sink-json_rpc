# frozen_string_literal: true

module ActiveDataFlow
  # Provides instrumentation and observability for data flow execution.
  #
  # This module integrates with Rails' ActiveSupport::Notifications to emit
  # events that can be subscribed to for monitoring, logging, and metrics.
  #
  # @example Subscribe to flow events
  #   ActiveDataFlow::Instrumentation.subscribe do |event|
  #     puts "Flow #{event[:flow_name]} #{event[:event_type]} in #{event[:duration]}ms"
  #   end
  #
  # @example Custom subscriber for specific events
  #   ActiveSupport::Notifications.subscribe("flow.completed.active_data_flow") do |event|
  #     Metrics.record_completion(event.payload)
  #   end
  #
  module Instrumentation
    # Event types emitted by the instrumentation system
    EVENTS = {
      flow_started: "flow.started.active_data_flow",
      flow_completed: "flow.completed.active_data_flow",
      flow_failed: "flow.failed.active_data_flow",
      flow_retried: "flow.retried.active_data_flow",
      flow_discarded: "flow.discarded.active_data_flow",
      batch_processed: "batch.processed.active_data_flow",
      job_enqueued: "job.enqueued.active_data_flow",
      job_performed: "job.performed.active_data_flow"
    }.freeze

    class << self
      # Install instrumentation subscribers
      def install!
        return if @installed

        subscribe_to_active_job
        @installed = true

        Rails.logger.info "[ActiveDataFlow::Instrumentation] Installed"
      end

      # Uninstall instrumentation subscribers
      def uninstall!
        @subscribers&.each do |subscriber|
          ActiveSupport::Notifications.unsubscribe(subscriber)
        end
        @subscribers = []
        @installed = false
      end

      # Subscribe to all ActiveDataFlow events
      #
      # @yield [Hash] Event payload
      def subscribe(&block)
        @custom_subscribers ||= []
        @custom_subscribers << block
      end

      # Clear custom subscribers
      def clear_subscribers!
        @custom_subscribers = []
      end

      # Instrument a flow execution
      #
      # @param event_type [Symbol] The event type (:flow_started, :flow_completed, etc.)
      # @param payload [Hash] Event payload
      # @yield Block to execute (for timing)
      def instrument(event_type, payload = {}, &block)
        event_name = EVENTS[event_type] || "#{event_type}.active_data_flow"

        ActiveSupport::Notifications.instrument(event_name, payload) do
          result = block_given? ? yield : nil
          notify_custom_subscribers(event_type, payload)
          result
        end
      end

      # Emit a flow started event
      def flow_started(flow:, run:, job: nil)
        payload = build_payload(flow: flow, run: run, job: job, event_type: :started)
        instrument(:flow_started, payload)
      end

      # Emit a flow completed event
      def flow_completed(flow:, run:, job: nil, duration: nil, records_processed: nil)
        payload = build_payload(
          flow: flow,
          run: run,
          job: job,
          event_type: :completed,
          duration: duration,
          records_processed: records_processed
        )
        instrument(:flow_completed, payload)
      end

      # Emit a flow failed event
      def flow_failed(flow:, run:, error:, job: nil, attempt: nil)
        payload = build_payload(
          flow: flow,
          run: run,
          job: job,
          event_type: :failed,
          error: error,
          attempt: attempt
        )
        instrument(:flow_failed, payload)
      end

      # Emit a flow retried event
      def flow_retried(flow:, run:, error:, attempt:, wait:, job: nil)
        payload = build_payload(
          flow: flow,
          run: run,
          job: job,
          event_type: :retried,
          error: error,
          attempt: attempt,
          retry_wait: wait
        )
        instrument(:flow_retried, payload)
      end

      # Emit a flow discarded event
      def flow_discarded(flow:, run:, error:, job: nil)
        payload = build_payload(
          flow: flow,
          run: run,
          job: job,
          event_type: :discarded,
          error: error
        )
        instrument(:flow_discarded, payload)
      end

      # Emit a batch processed event
      def batch_processed(flow:, run:, batch_size:, cursor:, total_processed:)
        payload = build_payload(
          flow: flow,
          run: run,
          event_type: :batch_processed,
          batch_size: batch_size,
          cursor: cursor,
          total_processed: total_processed
        )
        instrument(:batch_processed, payload)
      end

      private

      def subscribe_to_active_job
        @subscribers ||= []

        # Subscribe to ActiveJob perform events
        @subscribers << ActiveSupport::Notifications.subscribe("perform.active_job") do |event|
          job = event.payload[:job]
          next unless data_flow_job?(job)

          handle_job_performed(job, event)
        end

        # Subscribe to ActiveJob enqueue events
        @subscribers << ActiveSupport::Notifications.subscribe("enqueue.active_job") do |event|
          job = event.payload[:job]
          next unless data_flow_job?(job)

          handle_job_enqueued(job, event)
        end

        # Subscribe to ActiveJob retry events
        @subscribers << ActiveSupport::Notifications.subscribe("retry_stopped.active_job") do |event|
          job = event.payload[:job]
          next unless data_flow_job?(job)

          handle_job_retry_stopped(job, event)
        end

        # Subscribe to ActiveJob discard events
        @subscribers << ActiveSupport::Notifications.subscribe("discard.active_job") do |event|
          job = event.payload[:job]
          next unless data_flow_job?(job)

          handle_job_discarded(job, event)
        end
      end

      def data_flow_job?(job)
        job.is_a?(ActiveDataFlow::DataFlowJob) ||
          job.is_a?(ActiveDataFlow::ContinuableDataFlowJob) rescue false
      end

      def handle_job_performed(job, event)
        payload = {
          job_id: job.job_id,
          job_class: job.class.name,
          queue: job.queue_name,
          duration_ms: event.duration&.round(2),
          executions: job.executions,
          arguments: job.arguments
        }

        instrument(:job_performed, payload)
      end

      def handle_job_enqueued(job, event)
        payload = {
          job_id: job.job_id,
          job_class: job.class.name,
          queue: job.queue_name,
          scheduled_at: job.scheduled_at,
          arguments: job.arguments
        }

        instrument(:job_enqueued, payload)
      end

      def handle_job_retry_stopped(job, event)
        error = event.payload[:error]
        payload = {
          job_id: job.job_id,
          job_class: job.class.name,
          error_class: error&.class&.name,
          error_message: error&.message,
          executions: job.executions
        }

        instrument(:flow_failed, payload)
      end

      def handle_job_discarded(job, event)
        error = event.payload[:error]
        payload = {
          job_id: job.job_id,
          job_class: job.class.name,
          error_class: error&.class&.name,
          error_message: error&.message
        }

        instrument(:flow_discarded, payload)
      end

      def build_payload(flow: nil, run: nil, job: nil, event_type: nil, **extras)
        payload = {
          event_type: event_type,
          timestamp: Time.current.iso8601
        }

        if flow
          payload[:flow_id] = flow.id
          payload[:flow_name] = flow.name
          payload[:flow_status] = flow.status
        end

        if run
          payload[:run_id] = run.id
          payload[:run_status] = run.status
        end

        if job
          payload[:job_id] = job.job_id rescue nil
          payload[:job_class] = job.class.name
          payload[:executions] = job.executions rescue nil
        end

        if extras[:error]
          error = extras.delete(:error)
          payload[:error_class] = error.class.name
          payload[:error_message] = error.message&.truncate(500)
          payload[:error_classification] = ErrorHandling.classify_error(error) rescue :unknown
        end

        payload.merge(extras).compact
      end

      def notify_custom_subscribers(event_type, payload)
        @custom_subscribers&.each do |subscriber|
          subscriber.call(payload.merge(event_type: event_type))
        rescue StandardError => e
          Rails.logger.error "[Instrumentation] Subscriber error: #{e.message}"
        end
      end
    end
  end
end
