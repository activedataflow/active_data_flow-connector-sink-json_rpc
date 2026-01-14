# frozen_string_literal: true

require "dry/monads"

module ActiveDataFlow
  # Provides Result monad support for failable operations.
  #
  # Include this module in classes that need to return Success/Failure results
  # instead of raising exceptions. Provides Do notation for monadic chaining.
  #
  # @example Basic usage
  #   class MyService
  #     include ActiveDataFlow::Result
  #
  #     def call
  #       result = validate_input
  #       return result if result.failure?
  #
  #       Success(perform_operation)
  #     rescue StandardError => e
  #       Failure[:error, { message: e.message }]
  #     end
  #   end
  #
  # @example Do notation for chaining
  #   def call
  #     validated = yield validate_input
  #     processed = yield process(validated)
  #     Success(processed)
  #   end
  #
  module Result
    def self.included(base)
      base.include Dry::Monads[:result, :do]
      base.extend ClassMethods
    end

    # Class methods for Result module
    module ClassMethods
      include Dry::Monads[:result]

      # Wraps a block in a try/catch and returns a Result.
      #
      # @param failure_type [Symbol] the failure type to use if an exception is raised
      # @yield the block to execute
      # @return [Dry::Monads::Result] Success with block result or Failure with error details
      def try_result(failure_type = :error)
        Success(yield)
      rescue StandardError => e
        Failure[failure_type, {
          message: e.message,
          exception_class: e.class.name,
          backtrace: e.backtrace&.first(5)
        }]
      end
    end

    # Instance method version of try_result
    def try_result(failure_type = :error, &block)
      self.class.try_result(failure_type, &block)
    end
  end
end
