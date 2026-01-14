# frozen_string_literal: true

require "bundler/setup"
require "active_record"
require "active_data_flow"
require "fileutils"
require "tmpdir"

# Set up in-memory SQLite database for testing
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

# Create tables for testing
ActiveRecord::Schema.define do
  create_table :active_data_flow_data_flows, force: true do |t|
    t.string :name
    t.text :source
    t.text :sink
    t.text :runtime
    t.datetime :last_run_at
    t.datetime :next_run_at
    t.timestamps
  end

  create_table :active_data_flow_data_flow_runs, force: true do |t|
    t.references :data_flow
    t.string :status, default: 'pending'
    t.datetime :started_at
    t.datetime :ended_at
    t.datetime :scheduled_at
    t.text :error_message
    t.integer :records_processed, default: 0
    t.timestamps
  end
end

# Load support files
Dir[File.join(__dir__, "support", "**", "*.rb")].each { |f| require f }

# Load ActiveRecord models for testing
require_relative "../app/models/active_data_flow/active_record/data_flow"
require_relative "../app/models/active_data_flow/active_record/data_flow_run"

# Add lib to load path for submoduler tests
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true
  config.order = :random
  Kernel.srand config.seed
end
