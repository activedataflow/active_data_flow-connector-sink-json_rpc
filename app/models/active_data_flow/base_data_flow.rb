# frozen_string_literal: true

module ActiveDataFlow
  # Module containing common DataFlow functionality
  # This module defines shared behavior for both ActiveRecord and Redcord implementations
  module BaseDataFlow
    def self.included(base)
      base.extend(ClassMethods)
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

    def run
      # Cast to flow_class if needed to ensure we have the correct runtime
      flow_instance = cast_to_flow_class_if_needed
      flow_instance.send(:prepare_run)
      flow_instance.run_batch
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
    
    def prepare_run
      @source = rehydrate_connector(parsed_source)
      @sink = rehydrate_connector(parsed_sink)
      @runtime = rehydrate_runtime(parsed_runtime)
    end

    def rehydrate_connector(data)
      return nil unless data
      
      klass_name = data['class_name']
      unless klass_name
        Rails.logger.warn "[ActiveDataFlow] Connector class name missing in data: #{data.inspect}"
        return nil
      end
      
      klass = klass_name.constantize
      klass.from_json(data)
    rescue NameError => e
      Rails.logger.error "[ActiveDataFlow] Failed to load connector class: #{e.message}"
      nil
    end
    
    def rehydrate_runtime(data)
      return ActiveDataFlow::Runtime::Base.new unless data
      
      klass_name = data['class_name']
      unless klass_name
        Rails.logger.warn "[ActiveDataFlow] Runtime class name missing in data: #{data.inspect}"
        return ActiveDataFlow::Runtime::Base.new
      end
      
      klass = klass_name.constantize
      klass.from_json(data)
    rescue NameError => e
      Rails.logger.error "[ActiveDataFlow] Failed to load runtime class: #{e.message}"
      ActiveDataFlow::Runtime::Base.new
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