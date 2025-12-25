# frozen_string_literal: true

module ActiveDataFlow
  # Module containing common DataFlowRun functionality
  # This module defines shared behavior for both ActiveRecord and Redcord implementations
  module BaseDataFlowRun
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      # Class methods that subclasses should implement
      def create_pending_for_data_flow(data_flow)
        raise NotImplementedError, "Subclasses must implement create_pending_for_data_flow"
      end
      
      def due_to_run
        raise NotImplementedError, "Subclasses must implement due_to_run scope"
      end
      
      def pending
        raise NotImplementedError, "Subclasses must implement pending scope"
      end
      
      def in_progress
        raise NotImplementedError, "Subclasses must implement in_progress scope"
      end
      
      def success
        raise NotImplementedError, "Subclasses must implement success scope"
      end
      
      def completed
        raise NotImplementedError, "Subclasses must implement completed scope"
      end
      
      def due
        raise NotImplementedError, "Subclasses must implement due scope"
      end
      
      def overdue
        raise NotImplementedError, "Subclasses must implement overdue scope"
      end
    end

    # Common instance methods with shared implementation
    def duration
      return nil unless started_at && ended_at
      calculate_duration
    end

    def pending?
      status == 'pending'
    end

    def in_progress?
      status == 'in_progress'
    end

    def success?
      status == 'success'
    end

    def failed?
      status == 'failed'
    end

    def cancelled?
      status == 'cancelled'
    end

    def completed?
      success? || failed?
    end

    def due?
      pending? && run_after_time <= Time.current
    end

    def overdue?
      pending? && run_after_time <= 1.hour.ago
    end

    # Mark this run as started
    def start!
      data_flow.mark_run_started!(self)
    end

    # Mark this run as completed successfully
    def complete!
      data_flow.mark_run_completed!(self)
    end

    # Mark this run as failed
    def fail!(error)
      data_flow.mark_run_failed!(self, error)
    end

    # Abstract methods that subclasses must implement
    # Note: data_flow is NOT defined here because:
    # - ActiveRecord provides it via belongs_to (which uses GeneratedAssociationMethods)
    # - Redcord provides it explicitly in the class
    # Defining it here would override belongs_to due to Ruby's method lookup order

    protected
    
    # Helper methods that can be overridden by subclasses
    def calculate_duration
      # Default implementation assumes timestamps are in the same format
      # Subclasses can override if they use different timestamp formats
      ended_at - started_at
    end
    
    def run_after_time
      # Default implementation assumes run_after is a Time object
      # Subclasses can override if they use different timestamp formats (e.g., Unix timestamps)
      run_after
    end
  end
end