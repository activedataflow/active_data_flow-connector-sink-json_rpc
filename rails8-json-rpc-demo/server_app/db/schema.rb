# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_12_11_012158) do
  create_table "active_data_flow_data_flow_runs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "data_flow_id", null: false
    t.datetime "ended_at", precision: nil
    t.text "error_message"
    t.json "metadata"
    t.datetime "run_after", precision: nil, null: false
    t.datetime "started_at", precision: nil
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["data_flow_id", "run_after"], name: "idx_adf_runs_flow_id_run_after"
    t.index ["data_flow_id"], name: "index_active_data_flow_data_flow_runs_on_data_flow_id"
    t.index ["run_after"], name: "index_active_data_flow_data_flow_runs_on_run_after"
    t.index ["status"], name: "index_active_data_flow_data_flow_runs_on_status"
  end

  create_table "active_data_flow_data_flows", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "last_error"
    t.datetime "last_run_at", precision: nil
    t.string "name", null: false
    t.json "runtime"
    t.json "sink", null: false
    t.json "source", null: false
    t.string "status", default: "inactive"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_active_data_flow_data_flows_on_name", unique: true
    t.index ["status"], name: "index_active_data_flow_data_flows_on_status"
  end

  create_table "received_records", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "data", null: false
    t.datetime "processed_at"
    t.datetime "received_at"
    t.string "record_type", null: false
    t.integer "source_id", null: false
    t.datetime "updated_at", null: false
    t.index ["received_at"], name: "index_received_records_on_received_at"
    t.index ["record_type", "source_id"], name: "index_received_records_on_record_type_and_source_id"
    t.index ["record_type"], name: "index_received_records_on_record_type"
  end

  add_foreign_key "active_data_flow_data_flow_runs", "active_data_flow_data_flows", column: "data_flow_id"
end
