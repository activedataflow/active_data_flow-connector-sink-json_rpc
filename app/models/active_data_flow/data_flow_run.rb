# frozen_string_literal: true

module ActiveDataFlow
  class DataFlowRun < ApplicationRecord
    self.table_name = "active_data_flow_data_flow_runs"

    # Associations
    belongs_to :data_flow, class_name: "ActiveDataFlow::DataFlow"

    # Validations
    validates :status, inclusion: { in: %w[pending in_progress success failed cancelled] }
    validates :run_after, presence: true

    # Scopes
    scope :pending, -> { where(status: 'pending') }
    scope :in_progress, -> { where(status: 'in_progress') }
    scope :success, -> { where(status: 'success') }
    scope :completed, -> { where(status: ['success', 'failed']) }
    scope :due, -> { where(run_after: ..Time.current) }
    scope :overdue, -> { pending.where(run_after: ..1.hour.ago) }

    def self.create_pending_for_data_flow(data_flow)
      interval = data_flow.interval_seconds
      next_run = Time.current + interval
      
      data_flow.data_flow_runs.create!(
        status: 'pending',
        run_after: next_run
      )
    end

    # Tell Rails how to generate routes for this model
    def self.model_name
      @_model_name ||= ActiveModel::Name.new(self, ActiveDataFlow, "data_flow_run")
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
      pending? && run_after <= Time.current
    end

    def overdue?
      pending? && run_after <= 1.hour.ago
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
