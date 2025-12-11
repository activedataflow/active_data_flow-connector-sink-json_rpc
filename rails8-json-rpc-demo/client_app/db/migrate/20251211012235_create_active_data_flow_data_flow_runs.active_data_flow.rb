# frozen_string_literal: true

# This migration comes from active_data_flow (originally 20241126000001)
class CreateActiveDataFlowDataFlowRuns < ActiveRecord::Migration[6.0]
  def change
    create_table :active_data_flow_data_flow_runs do |t|
      t.references :data_flow, null: false, foreign_key: { to_table: :active_data_flow_data_flows }
      t.datetime :run_after, null: false
      t.datetime :started_at
      t.datetime :ended_at
      t.string :status, default: "pending", null: false
      t.text :error_message
      t.json :metadata

      t.timestamps
    end

    add_index :active_data_flow_data_flow_runs, :run_after
    add_index :active_data_flow_data_flow_runs, :status
    add_index :active_data_flow_data_flow_runs, [:data_flow_id, :run_after], name: "idx_adf_runs_flow_id_run_after"
  end
end