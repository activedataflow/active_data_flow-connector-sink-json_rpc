# frozen_string_literal: true

module ActiveDataFlow
  module Runtime
    module Redcord
      class DataFlow < ApplicationRecord
        self.table_name = "data_flows"

        # Associations
        has_many :data_flow_runs,
                 class_name: "ActiveDataFlow::Runtime::Redcord::DataFlowRun",
                 foreign_key: :data_flow_id,
                 dependent: :destroy

        # Validations
        validates :name, presence: true, uniqueness: true
        validates :run_interval, numericality: { greater_than: 0 }
        validates :last_run_status, inclusion: { in: %w[success failed], allow_nil: true }

        # Serialization
        serialize :configuration, JSON

        # Scopes
        scope :enabled, -> { where(enabled: true) }
        scope :due_to_run, lambda {
          enabled.where(
            "last_run_at IS NULL OR (julianday(?) - julianday(last_run_at)) * 86400 >= run_interval",
            Time.current
          )
        }

        # Instance Methods
        def trigger_run!
          FlowExecutor.execute(self)
        end

        def flow_class
          class_name = configuration.is_a?(Hash) ? configuration["class_name"] : configuration
          class_name.constantize
        end
      end
    end
  end
end
