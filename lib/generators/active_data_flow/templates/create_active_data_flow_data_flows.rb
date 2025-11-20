# frozen_string_literal: true

class CreateActiveDataFlowDataFlows < ActiveRecord::Migration[<%= ActiveRecord::Migration.current_version %>]
  def change
    create_table :active_data_flow_data_flows do |t|
      t.string :name, null: false
      t.string :source_type, null: false
      t.text :source_config
      t.string :sink_type, null: false
      t.text :sink_config
      t.string :runtime_type
      t.text :runtime_config
      t.string :status, default: "inactive"
      t.datetime :last_run_at
      t.text :last_error

      t.timestamps
    end

    add_index :active_data_flow_data_flows, :name, unique: true
    add_index :active_data_flow_data_flows, :status
  end
end
