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

    # === Progress Tracking for Job Continuations ===

    # Returns the current progress as a hash.
    #
    # @return [Hash] Progress information including step, cursor, records processed
    def progress
      return {} unless respond_to?(:metadata) && metadata.present?

      {
        step: metadata["current_step"],
        cursor: metadata["cursor"],
        records_processed: metadata["records_processed"],
        resumptions: metadata["resumptions"]
      }.compact
    end

    # Returns the current step name (for continuation jobs).
    #
    # @return [String, nil]
    def current_step
      metadata&.dig("current_step") if respond_to?(:metadata)
    end

    # Returns the current cursor position (for continuation jobs).
    #
    # @return [Object, nil]
    def current_cursor
      metadata&.dig("cursor") if respond_to?(:metadata)
    end

    # Returns the number of records processed so far.
    #
    # @return [Integer, nil]
    def records_processed
      metadata&.dig("records_processed") if respond_to?(:metadata)
    end

    # Returns how many times this job has been resumed.
    #
    # @return [Integer, nil]
    def resumption_count
      metadata&.dig("resumptions") if respond_to?(:metadata)
    end

    # Update progress information.
    #
    # @param step [String] Current step name
    # @param cursor [Object] Current cursor position
    # @param records [Integer] Records processed count
    # @param resumptions [Integer] Resumption count
    def update_progress(step: nil, cursor: nil, records: nil, resumptions: nil)
      return unless respond_to?(:metadata=)

      new_metadata = (metadata || {}).merge(
        "current_step" => step,
        "cursor" => cursor,
        "records_processed" => records,
        "resumptions" => resumptions,
        "progress_updated_at" => Time.current.iso8601
      ).compact

      update(metadata: new_metadata)
    end

    # Check if this run is resumable (has progress that can be continued).
    #
    # @return [Boolean]
    def resumable?
      in_progress? && current_cursor.present?
    end

    # Returns progress as a percentage (if total is known).
    #
    # @param total [Integer] Total records to process
    # @return [Float, nil] Percentage complete (0-100)
    def progress_percentage(total:)
      return nil unless records_processed && total.positive?

      ((records_processed.to_f / total) * 100).round(2)
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