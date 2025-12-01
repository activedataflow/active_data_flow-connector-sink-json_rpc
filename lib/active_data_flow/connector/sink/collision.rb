# frozen_string_literal: true

module ActiveDataFlow
  module Connector
    module Sink
        class Collision

            # Base class for all sink connectors

            # Possible WRITE results
            NO_PREDICTION = 0
            NEW_TRANSFORMED_RECORD = 1
            UPDATED_TRANSFORMED_RECORD = 2
            REDUNDENT_TRANSFORMED_RECORD = 3

            def predicted_write_result_string(enum)
                case enum
                when NO_PREDICTION then 'NO_PREDICTION'
                when UPDATED_TRANSFORMED_RECORD then 'UPDATED_TRANSFORMED_RECORD'
                when REDUNDENT_TRANSFORMED_RECORD then 'REDUNDENT_TRANSFORMED_RECORD'
                when NEW_TRANSFORMED_RECORD then 'NEW_TRANSFORMED_RECORD'
                else
                    "predicted_write_result #{enum} unexpected"
                end
            end
            
            def predicted_write_result(transformed:)
                NO_PREDICTION
            end

        end
    end
  end
end
