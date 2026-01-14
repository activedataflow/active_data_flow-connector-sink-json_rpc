# frozen_string_literal: true

require_relative '../base_data_flow'

module ActiveDataFlow
  module ActiveRecord
    class DataFlow < ::ActiveRecord::Base
      include ActiveDataFlow::BaseDataFlow
      include GlobalID::Identification

      self.table_name = "active_data_flow_data_flows"

      # Serialize JSON columns
      serialize :source, coder: JSON
      serialize :sink, coder: JSON
      serialize :runtime, coder: JSON

      # Associations
      has_many :data_flow_runs, dependent: :destroy, class_name: "ActiveDataFlow::ActiveRecord::DataFlowRun", foreign_key: :data_flow_id
      
      # Validations
      validates :name, presence: true, uniqueness: true
      validates :source, presence: true
      validates :sink, presence: true
      
      # Callbacks
      after_create :schedule_initial_run
      after_update :reschedule_if_needed
      
      # Scopes
      scope :active, -> { where(status: 'active') }
      scope :inactive, -> { where(status: 'inactive') }
      
      # Scope to find flows that have pending runs due to execute
      scope :due_to_run, -> {
        joins(:data_flow_runs)
          .where(status: 'active')
          .where(data_flow_runs: { status: 'pending', run_after: ..Time.current })
          .distinct
      }

      # Tell Rails how to generate routes for this model
      def self.model_name
        @_model_name ||= ActiveModel::Name.new(self, ActiveDataFlow, "data_flow")
      end
      
      def self.find_or_create(name:, source:, sink:, runtime:)
        flow = find_or_initialize_by(name: name)
        flow.source = source.as_json
        flow.sink = sink.as_json
        flow.runtime = runtime&.as_json
        flow.status = 'active'
        flow.save!
        flow
      end
      


      # Get the next pending run that's due
      def next_due_run
        data_flow_runs.pending.where(run_after: ..Time.current).order(:run_after).first
      end
       
      # Schedule the next run based on interval
      def schedule_next_run(from_time = Time.current)
        return unless enabled?
        
        next_run_time = from_time + interval_seconds.seconds
        data_flow_runs.create!(
          run_after: next_run_time,
          status: 'pending'
        )
      end
      
      # Mark a run as started and schedule the next one
      def mark_run_started!(run)
        run.update!(
          status: 'in_progress',
          started_at: Time.current
        )
        update(last_run_at: Time.current, last_error: nil)
        schedule_next_run
      end
      
      # Mark a run as completed successfully
      def mark_run_completed!(run)
        run.update!(
          status: 'success',
          ended_at: Time.current
        )
      end
      
      # Mark a run as failed
      def mark_run_failed!(run, error)
        run.update!(
          status: 'failed',
          ended_at: Time.current,
          error_message: error.to_s
        )
        update(last_error: error.to_s)
      end
      
      # ActiveRecord-specific implementation methods
      
      protected
      
      def cast_to_flow_class_if_needed
        if self.class == ActiveDataFlow::ActiveRecord::DataFlow && flow_class != ActiveDataFlow::ActiveRecord::DataFlow
          becomes(flow_class)
        else
          self
        end
      end
      
      def current_in_progress_run
        data_flow_runs.in_progress.first
      end
      
      def update_next_source_id(last_id)
        update(next_source_id: last_id)
      end
      
      def update_run_cursors(run, first_id, last_id)
        run.update(first_id: first_id, last_id: last_id)
      end

      private
      
      def parsed_source
        source
      end
      
      def parsed_sink
        sink
      end
      
      def parsed_runtime
        runtime
      end
      
      def schedule_initial_run
        return unless enabled?
        
        # Schedule first run immediately if active
        initial_run_time = status == 'active' ? Time.current : Time.current + interval_seconds.seconds
        data_flow_runs.create!(
          run_after: initial_run_time,
          status: 'pending'
        )
      end
      
      def reschedule_if_needed
        return unless saved_change_to_runtime? || saved_change_to_status?
        
        if status == 'active' && enabled?
          # Cancel any pending runs and schedule a new one
          data_flow_runs.pending.update_all(status: 'cancelled')
          schedule_next_run
        elsif status == 'inactive'
          # Cancel all pending runs
          data_flow_runs.pending.update_all(status: 'cancelled')
        end
      end
    end
  end
end
