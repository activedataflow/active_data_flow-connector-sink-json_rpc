# frozen_string_literal: true

# This migration comes from active_data_flow (originally 20241120000001)
class CreateActiveDataFlowDataFlows < ActiveRecord::Migration[6.0]
  def change
    create_table :active_data_flow_data_flows do |t|
      t.string :name, null: false
      t.json :source, null: false
      t.json :sink, null: false
      t.json :runtime
      t.string :status, default: "inactive"
      t.datetime :last_run_at
      t.text :last_error

      t.timestamps
    end

    add_index :active_data_flow_data_flows, :name, unique: true
    add_index :active_data_flow_data_flows, :status
  end
end
