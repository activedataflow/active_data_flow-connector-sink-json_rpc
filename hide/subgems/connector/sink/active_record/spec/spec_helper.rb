# frozen_string_literal: true

require 'active_record'
require 'database_cleaner/active_record'
require_relative 'support/active_data_flow_stub'
require_relative '../lib/active_data_flow/sink/active_record'
require_relative '../lib/active_data_flow/source/active_record'

# Set up in-memory SQLite database
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

# Create test schema
ActiveRecord::Schema.define do
  create_table :test_users, force: true do |t|
    t.string :name
    t.string :email
    t.timestamps
  end

  add_index :test_users, :email, unique: true
end

# Define test model
class TestUser < ActiveRecord::Base
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
end

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
