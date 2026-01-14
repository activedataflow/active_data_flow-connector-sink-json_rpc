# frozen_string_literal: true

module ActiveDataFlow
  module Connector
    module Sink
      # Base class for collision detection in sink connectors.
      # Subclass this to implement custom collision detection logic.
      #
      # @example
      #   class MySinkCollision < ActiveDataFlow::Connector::Sink::Collision
      #     def predicted_write_result(transformed:)
      #       if record_exists?(transformed)
      #         UPDATED_TRANSFORMED_RECORD
      #       else
      #         NEW_TRANSFORMED_RECORD
      #       end
      #     end
      #   end
      class Collision
        # Possible write result predictions
        NO_PREDICTION = 0
        NEW_TRANSFORMED_RECORD = 1
        UPDATED_TRANSFORMED_RECORD = 2
        REDUNDANT_TRANSFORMED_RECORD = 3

        # Backward compatibility alias for typo
        REDUNDENT_TRANSFORMED_RECORD = REDUNDANT_TRANSFORMED_RECORD

        # Returns a human-readable string for the prediction result.
        #
        # @param enum [Integer] The prediction constant
        # @return [String] Human-readable result name
        def predicted_write_result_string(enum)
          case enum
          when NO_PREDICTION then "NO_PREDICTION"
          when NEW_TRANSFORMED_RECORD then "NEW_TRANSFORMED_RECORD"
          when UPDATED_TRANSFORMED_RECORD then "UPDATED_TRANSFORMED_RECORD"
          when REDUNDANT_TRANSFORMED_RECORD then "REDUNDANT_TRANSFORMED_RECORD"
          else "UNKNOWN_RESULT(#{enum})"
          end
        end

        # Predicts the write result for a transformed record.
        # Override in subclasses to implement collision detection.
        #
        # @param transformed [Hash] The transformed record data
        # @return [Integer] One of the prediction constants
        def predicted_write_result(transformed:)
          NO_PREDICTION
        end
      end
    end
  end
end
