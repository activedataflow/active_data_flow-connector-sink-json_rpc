class CreateOutgoingRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :outgoing_records do |t|
      t.string :record_type, null: false
      t.json :data, null: false
      t.string :status, default: 'pending', null: false
      t.datetime :sent_at
      t.text :error_message
      t.integer :retry_count, default: 0

      t.timestamps
    end

    add_index :outgoing_records, :status
    add_index :outgoing_records, :record_type
    add_index :outgoing_records, :sent_at
  end
end
