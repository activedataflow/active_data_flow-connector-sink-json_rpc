class CreateDataFlowEngineApiGatewayConfigurations < ActiveRecord::Migration[7.0]
  def change
    create_table :data_flow_engine_api_gateway_configurations do |t|
      t.references :data_flow, null: false, foreign_key: { to_table: :data_flow_engine_data_flows }
      t.string :api_name, null: false
      t.string :api_id
      t.string :stage_name, default: 'production', null: false
      t.string :endpoint_url
      t.jsonb :routes, default: []
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :data_flow_engine_api_gateway_configurations, :api_name
    add_index :data_flow_engine_api_gateway_configurations, :api_id
    add_index :data_flow_engine_api_gateway_configurations, :stage_name
    add_index :data_flow_engine_api_gateway_configurations, :routes, using: :gin
  end
end
