class CreateDataFlowEngineKafkaConfigurations < ActiveRecord::Migration[7.0]
  def change
    create_table :data_flow_engine_kafka_configurations do |t|
      t.references :data_flow, null: false, foreign_key: { to_table: :data_flow_engine_data_flows }
      t.string :cluster_name, null: false
      t.string :cluster_arn
      t.jsonb :topics, default: []
      t.jsonb :broker_configuration, default: {}
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :data_flow_engine_kafka_configurations, :cluster_name
    add_index :data_flow_engine_kafka_configurations, :cluster_arn
    add_index :data_flow_engine_kafka_configurations, :topics, using: :gin
    add_index :data_flow_engine_kafka_configurations, :broker_configuration, using: :gin
  end
end
