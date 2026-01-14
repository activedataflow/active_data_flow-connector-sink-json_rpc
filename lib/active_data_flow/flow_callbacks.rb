# frozen_string_literal: true

module ActiveDataFlow
  # DSL for declaring callbacks on data flow classes.
  #
  # This module provides a way to define callbacks that execute after a flow
  # completes or fails, enabling flow chaining and coordination.
  #
  # @example Trigger another flow on completion
  #   class OrderExportFlow < ActiveDataFlow::DataFlow
  #     include ActiveDataFlow::FlowCallbacks
  #
  #     after_complete :notify_downstream
  #     after_complete :update_metrics
  #
  #     after_failure :alert_ops_team
  #
  #     private
  #
  #     def notify_downstream
  #       NotificationFlow.enqueue_now
  #     end
  #
  #     def update_metrics
  #       MetricsService.record_export_complete(name)
  #     end
  #
  #     def alert_ops_team
  #       OpsAlertService.notify("Flow #{name} failed")
  #     end
  #   end
  #
  # @example With flow dependencies
  #   class DataPipelineFlow < ActiveDataFlow::DataFlow
  #     include ActiveDataFlow::FlowCallbacks
  #
  #     # Chain to next flow in pipeline
  #     after_complete -> { EnrichmentFlow.enqueue_later(wait: 1.minute) }
  #
  #     # Conditional callback
  #     after_complete :sync_to_warehouse, if: :production?
  #   end
  #
  module FlowCallbacks
    def self.included(base)
      base.extend(ClassMethods)
      base.class_eval do
        class_attribute :_after_complete_callbacks, default: []
        class_attribute :_after_failure_callbacks, default: []
      end
    end

    module ClassMethods
      # Registers a callback to run after the flow completes successfully.
      #
      # @param method_name [Symbol, nil] Method to call on the flow instance
      # @param options [Hash] Options for the callback
      # @option options [Symbol, Proc] :if Condition for the callback to run
      # @option options [Symbol, Proc] :unless Condition for the callback to NOT run
      # @yield Block to execute as the callback
      def after_complete(method_name = nil, **options, &block)
        callback = build_callback(method_name, options, block)
        self._after_complete_callbacks = _after_complete_callbacks + [callback]
      end

      # Registers a callback to run after the flow fails.
      #
      # @param method_name [Symbol, nil] Method to call on the flow instance
      # @param options [Hash] Options for the callback
      # @option options [Symbol, Proc] :if Condition for the callback to run
      # @option options [Symbol, Proc] :unless Condition for the callback to NOT run
      # @yield Block to execute as the callback
      def after_failure(method_name = nil, **options, &block)
        callback = build_callback(method_name, options, block)
        self._after_failure_callbacks = _after_failure_callbacks + [callback]
      end

      # Enqueue this flow for immediate execution.
      #
      # @return [ActiveJob::Base, nil] The enqueued job
      def enqueue_now
        flow = find_by_flow_class(self)
        return unless flow&.enabled?

        ActiveDataFlow::DataFlowJob.perform_later(flow.id)
      end

      # Enqueue this flow for later execution.
      #
      # @param wait [ActiveSupport::Duration] Time to wait before execution
      # @param wait_until [Time] Specific time to execute
      # @return [ActiveJob::Base, nil] The enqueued job
      def enqueue_later(wait: nil, wait_until: nil)
        flow = find_by_flow_class(self)
        return unless flow&.enabled?

        job_options = {}
        job_options[:wait] = wait if wait
        job_options[:wait_until] = wait_until if wait_until

        ActiveDataFlow::DataFlowJob.set(**job_options).perform_later(flow.id)
      end

      private

      def build_callback(method_name, options, block)
        {
          method: method_name,
          block: block,
          if: options[:if],
          unless: options[:unless]
        }
      end

      def find_by_flow_class(klass)
        # Try to find the flow by class name convention
        flow_name = klass.name.underscore.gsub("_flow", "")
        ActiveDataFlow::DataFlow.find_by(name: flow_name) ||
          ActiveDataFlow::DataFlow.find_by(name: klass.name.underscore)
      end
    end

    # Runs all after_complete callbacks.
    #
    # @param run [DataFlowRun, nil] The completed run (for context)
    # @return [Array] Results from callbacks
    def run_after_complete_callbacks(run = nil)
      run_callbacks(_after_complete_callbacks, run)
    end

    # Runs all after_failure callbacks.
    #
    # @param run [DataFlowRun, nil] The failed run (for context)
    # @param error [Exception, nil] The error that caused the failure
    # @return [Array] Results from callbacks
    def run_after_failure_callbacks(run = nil, error = nil)
      @_last_error = error
      run_callbacks(_after_failure_callbacks, run)
    end

    # Returns the last error from the flow execution.
    # Available in after_failure callbacks.
    #
    # @return [Exception, nil]
    def last_error
      @_last_error
    end

    private

    def run_callbacks(callbacks, run)
      callbacks.map do |callback|
        next unless should_run_callback?(callback)

        begin
          execute_callback(callback, run)
        rescue StandardError => e
          Rails.logger.error "[FlowCallbacks] Callback failed: #{e.message}"
          Rails.logger.error e.backtrace.first(5).join("\n")
          nil
        end
      end.compact
    end

    def should_run_callback?(callback)
      # Check :if condition
      if callback[:if]
        condition = callback[:if]
        result = condition.is_a?(Proc) ? instance_exec(&condition) : send(condition)
        return false unless result
      end

      # Check :unless condition
      if callback[:unless]
        condition = callback[:unless]
        result = condition.is_a?(Proc) ? instance_exec(&condition) : send(condition)
        return false if result
      end

      true
    end

    def execute_callback(callback, run)
      if callback[:block]
        instance_exec(run, &callback[:block])
      elsif callback[:method]
        if method(callback[:method]).arity == 0
          send(callback[:method])
        else
          send(callback[:method], run)
        end
      end
    end
  end
end
