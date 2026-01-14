# frozen_string_literal: true

module ActiveDataFlow
  module Connector
    module Sink
      class Base

        # Base class for all sink connector
        attr_reader :model_class, :sink_collision_class, :collision_detector, :options
        
        def initialize(model_class:, sink_collision_class: nil, **options)
          @model_class = model_class
          @sink_collision_class = sink_collision_class
          @collision_detector = sink_collision_class&.new
          @options = options
        end

        # Write a record to the sink
        def write(transformed)
          if @collision_detector
            result_enum = @collision_detector.predicted_write_result(transformed: transformed)
            result_string = @collision_detector.predicted_write_result_string(result_enum)
            Rails.logger.info("[DataFlow.sink] predicted_write_result: #{result_string}")
            
            # Act on collision detection results
            case result_enum
            when ActiveDataFlow::Connector::Sink::Collision::REDUNDANT_TRANSFORMED_RECORD
              # Skip writing - record already exists with same data
              Rails.logger.debug("[DataFlow.sink] Skipping redundant record")
              return
            when ActiveDataFlow::Connector::Sink::Collision::UPDATED_TRANSFORMED_RECORD
              # Update existing record
              existing_id = @collision_detector.get_transformed_id(transformed)
              existing = @model_class.find_by(product_id: existing_id)
              if existing
                existing.update!(transformed)
                Rails.logger.info("[DataFlow.sink] Updated existing record: #{existing_id}")
              end
              return
            end
          end
          
          # Create new record (NEW_TRANSFORMED_RECORD or NO_PREDICTION)
          record = @model_class.new(transformed)
          record.save!
        end

        # Write multiple records to the sink
        #def write_batch(records)
        #  records.each { |record| write(record) }
        #end
        
        # Flush any buffered writes
        def flush
          # Override in subclasses if needed
        end
        
        # Close the sink and release resources
        def close
          flush
        end
        
        # Serialize to JSON
        def as_json(*_args)
          @options.merge('class_name' => self.class.name)
        end
        
        # Deserialize from JSON
        def self.from_json(data)
          data = data.symbolize_keys
          data.delete(:class_name) # Remove class_name as it's not a constructor parameter
          new(**data)
        end
      end
    end
  end
end
