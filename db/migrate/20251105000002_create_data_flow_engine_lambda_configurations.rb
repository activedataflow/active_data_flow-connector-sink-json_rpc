class CreateDataFlowEngineLambdaConfigurations < ActiveRecord::Migration[7.0]
  def change
    create_table :data_flow_engine_lambda_configurations do |t|
      t.references :data_flow, null: false, foreign_key: { to_table: :data_flow_engine_data_flows }
      t.string :function_name, null: false
      t.text :function_code
      t.string :code_language, default: 'ruby', null: false
      t.string :runtime, null: false
      t.string :handler, null: false
      t.integer :memory_size, default: 512, null: false
      t.integer :timeout, default: 30, null: false
      t.jsonb :environment_variables, default: {}
      t.string :aws_function_arn
      t.string :aws_version
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :data_flow_engine_lambda_configurations, :function_name
    add_index :data_flow_engine_lambda_configurations, :code_language
    add_index :data_flow_engine_lambda_configurations, :aws_function_arn
    add_index :data_flow_engine_lambda_configurations, :environment_variables, using: :gin
  end
end
