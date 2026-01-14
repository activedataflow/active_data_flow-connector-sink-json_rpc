# frozen_string_literal: true

module ActiveDataFlow
  module Runtime
    module Heartbeat
      class FlowRunExecutor
        include ActiveDataFlow::Result

        def self.execute(data_flow_run)
          new(data_flow_run).execute
        end

        def initialize(data_flow_run)
          @data_flow_run = data_flow_run
          @data_flow = data_flow_run.data_flow
        end

        # Executes the data flow run.
        #
        # @return [Dry::Monads::Result] Success(:completed) or Failure[:execution_error, {...}]
        def execute
          Rails.logger.info "[FlowRunExecutor] Starting: #{@data_flow.name}: run #{@data_flow_run.id}"

          # Mark run as in progress and schedule next run
          @data_flow.mark_run_started!(@data_flow_run)

          Rails.logger.info "[FlowExecutor] Running flow instance"
          # Delegate execution to the data flow model, which handles casting/rehydration
          run_result = @data_flow.run

          case run_result
          in Dry::Monads::Result::Failure(failure)
            handle_failure(failure)
            run_result
          in Dry::Monads::Result::Success
            # Mark run as successful
            @data_flow.mark_run_completed!(@data_flow_run)
            Rails.logger.info "[FlowExecutor] Flow completed successfully"
            run_result
          end
        rescue StandardError => e
          Rails.logger.error "[FlowExecutor] Flow failed with exception: #{e.message}"
          # Mark run as failed
          @data_flow.mark_run_failed!(@data_flow_run, e)
          Failure[:execution_error, {
            message: e.message,
            exception_class: e.class.name,
            backtrace: e.backtrace&.first(10)
          }]
        end

        private

        # Handles a failure result from the flow execution.
        #
        # @param failure [Array] The failure data [type, details]
        def handle_failure(failure)
          failure_type, details = failure
          message = details.is_a?(Hash) ? details[:message] : details.to_s

          Rails.logger.error "[FlowExecutor] Flow failed: #{message}"

          # Convert failure to an exception for the mark_run_failed! method
          error = StandardError.new(message)
          @data_flow.mark_run_failed!(@data_flow_run, error)
        end
      end
    end
  end
end
