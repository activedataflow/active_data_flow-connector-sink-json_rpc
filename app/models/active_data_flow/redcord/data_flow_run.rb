# frozen_string_literal: true

module ActiveDataFlow
  module Redcord
    class DataFlowRun
      include ::Redcord::Base

      # Schema definition
      attribute :data_flow_id, :string
      attribute :status, :string
      attribute :run_after, :integer    # Unix timestamp
      attribute :started_at, :integer
      attribute :ended_at, :integer
      attribute :error_message, :string
      attribute :first_id, :string
      attribute :last_id, :string
      attribute :created_at, :integer
      attribute :updated_at, :integer

      # Indexes
      range_index :data_flow_id
      range_index :status
      range_index :run_after

      # Validations
      validates :status, inclusion: { in: %w[pending in_progress success failed cancelled] }
      validates :run_after, presence: true

      # Tell Rails how to generate routes for this model
      def self.model_name
        @_model_name ||= ActiveModel::Name.new(self, ActiveDataFlow, "data_flow_run")
      end

      def self.create_pending_for_data_flow(data_flow)
        interval = data_flow.interval_seconds
        next_run = Time.current.to_i + interval

        create!(
          data_flow_id: data_flow.id,
          status: 'pending',
          run_after: next_run,
          created_at: Time.current.to_i,
          updated_at: Time.current.to_i
        )
      end

      # Association helper
      def data_flow
        ActiveDataFlow::Redcord::DataFlow.find(data_flow_id)
      end

      # Scopes (implemented as class methods)
      def self.due_to_run
        where(status: 'pending').select { |run| run.run_after <= Time.current.to_i }
      end

      def self.pending
        where(status: 'pending')
      end

      def self.in_progress
        where(status: 'in_progress')
      end

      def self.success
        where(status: 'success')
      end

      def self.completed
        all.select { |run| run.completed? }
      end

      def self.due
        all.select { |run| run.run_after <= Time.current.to_i }
      end

      def self.overdue
        pending.select { |run| run.run_after <= 1.hour.ago.to_i }
      end

      # Instance Methods
      def duration
        return nil unless started_at && ended_at
        ended_at - started_at
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
        pending? && run_after <= Time.current.to_i
      end

      def overdue?
        pending? && run_after <= 1.hour.ago.to_i
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
    end
  end
end
