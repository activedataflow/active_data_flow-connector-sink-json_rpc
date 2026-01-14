# frozen_string_literal: true

module ActiveDataFlow
  # Module containing common DataFlow functionality
  # This module defines shared behavior for both ActiveRecord and Redcord implementations
  module BaseDataFlow
    def self.included(base)
      base.extend(ClassMethods)
      base.include(ActiveDataFlow::Result)
    end
    
    module ClassMethods
      # Class methods that subclasses should implement
      def find_or_create(name:, source:, sink:, runtime:)
        raise NotImplementedError, "Subclasses must implement find_or_create"
      end
      
      def active
        raise NotImplementedError, "Subclasses must implement active scope"
      end
      
      def inactive
        raise NotImplementedError, "Subclasses must implement inactive scope"
      end
      
      def due_to_run
        raise NotImplementedError, "Subclasses must implement due_to_run scope"
      end
    end
    
    # Instance methods with common implementation
    def interval_seconds
      parsed_runtime&.dig('interval') || 3600
    end

    def enabled?
      parsed_runtime&.dig('enabled') == true
    end

    # Returns the concurrency group for this flow (from runtime config).
    #
    # @return [String, nil] The concurrency group name
    def concurrency_group
      parsed_runtime&.dig('concurrency_group')
    end

    # Returns the concurrency limit for this flow (from runtime config).
    #
    # @return [Integer] The concurrency limit (default: 1)
    def concurrency_limit
      parsed_runtime&.dig('concurrency_limit') || 1
    end

    # Returns the concurrency group limit for this flow (from runtime config).
    #
    # @return [Integer, nil] The group concurrency limit
    def concurrency_group_limit
      parsed_runtime&.dig('concurrency_group_limit')
    end

    # Returns the concurrency key for SolidQueue.
    #
    # @return [String] The concurrency key
    def concurrency_key
      if concurrency_group.present?
        "active_data_flow:group:#{concurrency_group}"
      else
        "active_data_flow:flow:#{name}"
      end
    end

    # Returns the effective concurrency limit for this flow.
    #
    # @return [Integer] The effective limit
    def effective_concurrency_limit
      if concurrency_group.present? && concurrency_group_limit
        concurrency_group_limit
      else
        concurrency_limit
      end
    end

    def run_one(message)
      transformed = @runtime.transform(message)
      @sink.write(transformed)
      @count += 1
    end

    def run_batch
      @count = 0
      first_id = nil
      last_id = nil
      
      # Pass batch_size and cursor to source for incremental processing
      @source.each(batch_size: @runtime.batch_size, start_id: next_source_id) do |message|
        # Track cursors
        current_id = message_id(message)
        first_id ||= current_id
        last_id = current_id
        
        run_one(message)
        break if @count >= @runtime.batch_size
      end
      
      # Update cursor on DataFlow to track progress
      if last_id
        update_next_source_id(last_id)
        Rails.logger.info("[DataFlow] Advanced cursor to #{last_id}")
        
        # Also update the run record for tracking
        if current_run = current_in_progress_run
          update_run_cursors(current_run, first_id, last_id)
        end
      end
    rescue StandardError => e
      Rails.logger.error("DataFlow error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      raise
    end

    # Executes the data flow.
    #
    # @return [Dry::Monads::Result] Success or Failure with error details
    def run
      # Cast to flow_class if needed to ensure we have the correct runtime
      flow_instance = cast_to_flow_class_if_needed
      result = flow_instance.send(:prepare_run)

      case result
      in Dry::Monads::Result::Failure
        return result
      in Dry::Monads::Result::Success
        flow_instance.run_batch
        Success(:completed)
      end
    end

    def heartbeat_event
      schedule_next_run
    end

    def flow_class
      name.camelize.constantize
    end

    # Abstract methods that subclasses must implement
    # Note: data_flow_runs is NOT defined here because:
    # - ActiveRecord provides it via has_many (which uses GeneratedAssociationMethods)
    # - Redcord provides it explicitly in the class
    # Defining it here would override has_many due to Ruby's method lookup order

    def next_due_run
      raise NotImplementedError, "Subclasses must implement next_due_run"
    end
    
    def schedule_next_run(from_time = Time.current)
      raise NotImplementedError, "Subclasses must implement schedule_next_run"
    end
    
    def mark_run_started!(run)
      raise NotImplementedError, "Subclasses must implement mark_run_started!"
    end
    
    def mark_run_completed!(run)
      raise NotImplementedError, "Subclasses must implement mark_run_completed!"
    end
    
    def mark_run_failed!(run, error)
      raise NotImplementedError, "Subclasses must implement mark_run_failed!"
    end

    protected
    
    # Helper methods that can be overridden by subclasses
    def cast_to_flow_class_if_needed
      # Default implementation - subclasses can override
      self
    end
    
    def current_in_progress_run
      # Default implementation - subclasses can override
      data_flow_runs.find { |r| r.in_progress? }
    end
    
    def update_next_source_id(last_id)
      # Abstract method - subclasses must implement
      raise NotImplementedError, "Subclasses must implement update_next_source_id"
    end
    
    def update_run_cursors(run, first_id, last_id)
      # Abstract method - subclasses must implement
      raise NotImplementedError, "Subclasses must implement update_run_cursors"
    end

    private

    # Prepares the flow for execution by rehydrating connectors and runtime.
    #
    # @return [Dry::Monads::Result] Success(true) or Failure[:deserialization_error, {...}]
    def prepare_run
      source_result = rehydrate_connector(parsed_source)
      sink_result = rehydrate_connector(parsed_sink)
      runtime_result = rehydrate_runtime(parsed_runtime)

      # Use Do notation to unwrap results
      @source = yield source_result
      @sink = yield sink_result
      @runtime = yield runtime_result

      Success(true)
    end

    # Rehydrates a connector from serialized JSON data.
    #
    # @param data [Hash, nil] The serialized connector data
    # @return [Dry::Monads::Result] Success(connector) or Failure[:deserialization_error, {...}]
    def rehydrate_connector(data)
      unless data
        return Failure[:deserialization_error, {
          message: "No connector data provided"
        }]
      end

      klass_name = data["class_name"]
      unless klass_name
        Rails.logger.warn "[ActiveDataFlow] Connector class name missing in data: #{data.inspect}"
        return Failure[:deserialization_error, {
          message: "Connector class name missing",
          data: data
        }]
      end

      klass = klass_name.constantize
      Success(klass.from_json(data))
    rescue NameError => e
      Rails.logger.error "[ActiveDataFlow] Failed to load connector class: #{e.message}"
      Failure[:deserialization_error, {
        message: e.message,
        class_name: klass_name,
        exception_class: e.class.name
      }]
    end

    # Rehydrates a runtime from serialized JSON data.
    #
    # @param data [Hash, nil] The serialized runtime data
    # @return [Dry::Monads::Result] Success(runtime) - always succeeds with default fallback
    def rehydrate_runtime(data)
      unless data
        return Success(ActiveDataFlow::Runtime::Base.new)
      end

      klass_name = data["class_name"]
      unless klass_name
        Rails.logger.warn "[ActiveDataFlow] Runtime class name missing in data: #{data.inspect}"
        return Success(ActiveDataFlow::Runtime::Base.new)
      end

      klass = klass_name.constantize
      Success(klass.from_json(data))
    rescue NameError => e
      Rails.logger.error "[ActiveDataFlow] Failed to load runtime class: #{e.message}"
      # Runtime failures fall back to base runtime (intentional)
      Success(ActiveDataFlow::Runtime::Base.new)
    end

    # Override in subclasses to customize message ID extraction
    def message_id(message)
      message['id']
    end

    # Override in subclasses to implement collision detection
    def transform_collision(message, transformed)
      Rails.logger.debug("[DataFlow] Collision detection not implemented for this flow")
      nil
    end
    
    # Abstract methods for JSON parsing - subclasses must implement
    def parsed_source
      raise NotImplementedError, "Subclasses must implement parsed_source"
    end
    
    def parsed_sink
      raise NotImplementedError, "Subclasses must implement parsed_sink"
    end
    
    def parsed_runtime
      raise NotImplementedError, "Subclasses must implement parsed_runtime"
    end
  end
end