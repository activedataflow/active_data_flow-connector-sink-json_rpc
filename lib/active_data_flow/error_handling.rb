# frozen_string_literal: true

module ActiveDataFlow
  # Provides configurable error handling strategies for data flow jobs.
  #
  # This module centralizes error handling configuration, allowing flows to
  # define custom retry policies, error categorization, and failure handling.
  #
  # @example Configure global error handling
  #   ActiveDataFlow::ErrorHandling.configure do |config|
  #     config.max_attempts = 5
  #     config.retry_wait = :polynomially_longer
  #     config.on_permanent_failure = ->(flow, error) { AlertService.notify(error) }
  #   end
  #
  # @example Define flow-specific retry policy
  #   class MyFlow < ActiveDataFlow::DataFlow
  #     include ActiveDataFlow::ErrorHandling::FlowMixin
  #
  #     retry_policy max_attempts: 10,
  #                  retry_on: [Net::OpenTimeout, Faraday::TimeoutError],
  #                  discard_on: [ActiveRecord::RecordNotFound]
  #   end
  #
  module ErrorHandling
    # Error categories for classification
    TRANSIENT_ERRORS = [
      "ActiveRecord::Deadlocked",
      "ActiveRecord::LockWaitTimeout",
      "PG::TRDeadlockDetected",
      "Mysql2::Error::ConnectionError",
      "Redis::TimeoutError",
      "Net::OpenTimeout",
      "Net::ReadTimeout",
      "Faraday::TimeoutError",
      "Faraday::ConnectionFailed",
      "Errno::ECONNREFUSED",
      "Errno::ECONNRESET",
      "SocketError"
    ].freeze

    PERMANENT_ERRORS = [
      "ActiveJob::DeserializationError",
      "ActiveRecord::RecordNotFound",
      "ActiveRecord::RecordInvalid",
      "ArgumentError",
      "NoMethodError",
      "NameError"
    ].freeze

    class Configuration
      attr_accessor :max_attempts, :retry_wait, :retry_jitter,
                    :transient_errors, :permanent_errors,
                    :on_retry, :on_permanent_failure, :on_discard,
                    :track_errors, :error_ttl

      def initialize
        @max_attempts = 5
        @retry_wait = :polynomially_longer
        @retry_jitter = 0.15
        @transient_errors = TRANSIENT_ERRORS.dup
        @permanent_errors = PERMANENT_ERRORS.dup
        @on_retry = nil
        @on_permanent_failure = nil
        @on_discard = nil
        @track_errors = true
        @error_ttl = 7.days
      end

      # Add a transient error class (will be retried)
      def add_transient_error(error_class)
        @transient_errors << error_class.to_s unless @transient_errors.include?(error_class.to_s)
      end

      # Add a permanent error class (will be discarded)
      def add_permanent_error(error_class)
        @permanent_errors << error_class.to_s unless @permanent_errors.include?(error_class.to_s)
      end

      # Calculate wait time for a given attempt
      def wait_time_for(attempt)
        case retry_wait
        when :polynomially_longer
          polynomial_wait(attempt)
        when :exponentially_longer
          exponential_wait(attempt)
        when Numeric
          retry_wait
        when Proc
          retry_wait.call(attempt)
        else
          polynomial_wait(attempt)
        end
      end

      private

      def polynomial_wait(attempt)
        base = (attempt**4) + 2
        jitter = base * retry_jitter * rand
        base + jitter
      end

      def exponential_wait(attempt)
        base = (2**attempt)
        jitter = base * retry_jitter * rand
        base + jitter
      end
    end

    class << self
      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration)
      end

      def reset_configuration!
        @configuration = Configuration.new
      end

      # Classify an error as transient, permanent, or unknown
      #
      # @param error [Exception] The error to classify
      # @return [Symbol] :transient, :permanent, or :unknown
      def classify_error(error)
        error_class = error.class.name

        if configuration.transient_errors.any? { |e| matches_error_class?(error, error_class, e) }
          :transient
        elsif configuration.permanent_errors.any? { |e| matches_error_class?(error, error_class, e) }
          :permanent
        else
          :unknown
        end
      end

      private

      def matches_error_class?(error, error_class_name, configured_class)
        return true if error_class_name.include?(configured_class)

        begin
          klass = configured_class.constantize
          error.is_a?(klass)
        rescue NameError
          false
        end
      end

      public

      # Check if an error should be retried
      #
      # @param error [Exception] The error to check
      # @return [Boolean]
      def retriable?(error)
        classification = classify_error(error)
        classification == :transient || classification == :unknown
      end

      # Check if an error should cause the job to be discarded
      #
      # @param error [Exception] The error to check
      # @return [Boolean]
      def discardable?(error)
        classify_error(error) == :permanent
      end
    end

    # Mixin for flow classes to define custom retry policies
    module FlowMixin
      def self.included(base)
        base.extend(ClassMethods)
        base.class_eval do
          class_attribute :_retry_policy, default: {}
        end
      end

      module ClassMethods
        # Define a retry policy for this flow
        #
        # @param max_attempts [Integer] Maximum retry attempts
        # @param retry_on [Array<Class>] Error classes to retry
        # @param discard_on [Array<Class>] Error classes to discard
        # @param wait [Symbol, Numeric, Proc] Wait strategy between retries
        def retry_policy(max_attempts: nil, retry_on: [], discard_on: [], wait: nil)
          self._retry_policy = {
            max_attempts: max_attempts,
            retry_on: Array(retry_on).map(&:to_s),
            discard_on: Array(discard_on).map(&:to_s),
            wait: wait
          }.compact
        end

        # Get the effective retry policy (flow-specific or global)
        def effective_retry_policy
          global = ErrorHandling.configuration
          flow = _retry_policy

          {
            max_attempts: flow[:max_attempts] || global.max_attempts,
            retry_on: flow[:retry_on].presence || global.transient_errors,
            discard_on: flow[:discard_on].presence || global.permanent_errors,
            wait: flow[:wait] || global.retry_wait
          }
        end
      end

      # Instance method to get the retry policy
      def retry_policy
        self.class.effective_retry_policy
      end
    end

    # Error tracking for monitoring and debugging
    class ErrorTracker
      class << self
        # Record an error occurrence
        #
        # @param flow [DataFlow] The flow that failed
        # @param error [Exception] The error
        # @param run [DataFlowRun, nil] The run record
        # @param attempt [Integer] The attempt number
        def record(flow:, error:, run: nil, attempt: 1)
          return unless ErrorHandling.configuration.track_errors

          entry = {
            flow_name: flow.name,
            flow_id: flow.id,
            run_id: run&.id,
            error_class: error.class.name,
            error_message: truncate_message(error.message),
            error_classification: ErrorHandling.classify_error(error),
            backtrace: error.backtrace&.first(10),
            attempt: attempt,
            occurred_at: Time.current.iso8601
          }

          store_error(entry)
          notify_callbacks(flow, error, entry)

          entry
        end

        # Get recent errors for a flow
        #
        # @param flow_name [String] The flow name
        # @param limit [Integer] Max errors to return
        # @return [Array<Hash>]
        def recent_errors(flow_name: nil, limit: 100)
          errors = load_errors
          errors = errors.select { |e| e[:flow_name] == flow_name } if flow_name
          errors.last(limit)
        end

        # Get error statistics
        #
        # @return [Hash] Error counts by flow and classification
        def statistics
          errors = load_errors
          cutoff = 24.hours.ago

          recent = errors.select { |e| Time.parse(e[:occurred_at]) > cutoff rescue false }

          {
            total_24h: recent.size,
            by_flow: recent.group_by { |e| e[:flow_name] }.transform_values(&:size),
            by_classification: recent.group_by { |e| e[:error_classification] }.transform_values(&:size),
            by_error_class: recent.group_by { |e| e[:error_class] }.transform_values(&:size)
          }
        end

        # Clear old errors
        def cleanup!
          ttl = ErrorHandling.configuration.error_ttl
          cutoff = ttl.ago

          errors = load_errors.reject do |e|
            Time.parse(e[:occurred_at]) < cutoff rescue true
          end

          save_errors(errors)
        end

        private

        def truncate_message(message, max_length: 1000)
          return "" unless message

          message.length > max_length ? "#{message[0, max_length]}..." : message
        end

        def store_error(entry)
          errors = load_errors
          errors << entry
          save_errors(errors)
        end

        def notify_callbacks(flow, error, entry)
          config = ErrorHandling.configuration

          if entry[:error_classification] == :permanent && config.on_permanent_failure
            config.on_permanent_failure.call(flow, error, entry)
          elsif config.on_retry && entry[:attempt] > 1
            config.on_retry.call(flow, error, entry)
          end
        rescue StandardError => e
          Rails.logger.error "[ErrorTracker] Callback failed: #{e.message}"
        end

        def load_errors
          return @errors ||= [] unless defined?(Rails) && Rails.cache

          Rails.cache.fetch("active_data_flow:errors", expires_in: 1.day) { [] }
        end

        def save_errors(errors)
          return @errors = errors unless defined?(Rails) && Rails.cache

          # Keep only recent errors to prevent unbounded growth
          max_errors = 10_000
          errors = errors.last(max_errors) if errors.size > max_errors

          Rails.cache.write("active_data_flow:errors", errors, expires_in: 1.day)
        end
      end
    end
  end
end
