class CreateReceivedRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :received_records do |t|
      t.string :record_type, null: false
      t.integer :source_id, null: false
      t.json :data, null: false
      t.datetime :received_at
      t.datetime :processed_at

      t.timestamps
    end

    add_index :received_records, :record_type
    add_index :received_records, :received_at
    add_index :received_records, [:record_type, :source_id]
  end
end
