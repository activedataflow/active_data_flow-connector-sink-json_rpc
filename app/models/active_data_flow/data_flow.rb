# frozen_string_literal: true

module ActiveDataFlow
  class DataFlow < ApplicationRecord
    validates :name, presence: true, uniqueness: true
    validates :source, presence: true
    validates :sink, presence: true
    
    # Scopes
    scope :active, -> { where(status: 'active') }
    scope :inactive, -> { where(status: 'inactive') }
    
    scope :due_to_run, -> {
      where(status: 'active').where(
        'last_run_at IS NULL OR last_run_at <= ?',
        Time.current - 3600
      )
    }
    
    def self.find_or_create(name:, source:, sink:, runtime:)
      flow = find_or_initialize_by(name: name)
      flow.source = source.as_json
      flow.sink = sink.as_json
      flow.runtime = runtime&.as_json
      flow.status = 'active'
      flow.save!
      flow
    end
    
    def interval_seconds
      runtime&.dig('interval') || 3600
    end
    
    def mark_run_started!
      update(last_run_at: Time.current, last_error: nil)
    end
    
    def mark_run_failed!(error)
      update(last_error: error.to_s, status: 'failed')
    end
  end
end
