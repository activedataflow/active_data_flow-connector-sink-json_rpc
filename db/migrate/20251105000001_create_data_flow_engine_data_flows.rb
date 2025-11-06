class CreateDataFlowEngineDataFlows < ActiveRecord::Migration[7.0]
  def change
    create_table :data_flow_engine_data_flows do |t|
      t.string :name, null: false, index: { unique: true }
      t.text :description
      t.string :status, default: 'draft', null: false
      t.string :aws_sync_status, default: 'not_synced'
      t.datetime :last_synced_at
      t.jsonb :configuration, default: {}
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :data_flow_engine_data_flows, :status
    add_index :data_flow_engine_data_flows, :aws_sync_status
    add_index :data_flow_engine_data_flows, :configuration, using: :gin
    add_index :data_flow_engine_data_flows, :metadata, using: :gin
  end
end
