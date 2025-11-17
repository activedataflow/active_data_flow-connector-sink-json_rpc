# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Source and Sink Integration' do
  before do
    # Create source table with data
    TestUser.create!(name: 'User 1', email: 'user1@example.com')
    TestUser.create!(name: 'User 2', email: 'user2@example.com')
    TestUser.create!(name: 'User 3', email: 'user3@example.com')
  end

  describe 'reading and writing data' do
    it 'reads from source and writes to sink' do
      source = ActiveDataFlow::Source::ActiveRecord.new(model_name: 'TestUser')
      sink = ActiveDataFlow::Sink::ActiveRecord.new(model_name: 'TestUser', batch_size: 2)

      # Clear existing data
      TestUser.delete_all

      # Re-create source data
      TestUser.create!(name: 'User 1', email: 'user1@example.com')
      TestUser.create!(name: 'User 2', email: 'user2@example.com')

      # Read from source and write to sink (simulating data transformation)
      records_to_write = []
      source.each do |record|
        records_to_write << {
          name: "#{record.name} (copied)",
          email: "copy_#{record.email}"
        }
      end

      # Clear again to test writing
      TestUser.delete_all

      # Write using sink
      records_to_write.each { |record| sink.write(record) }
      sink.close

      # Verify data was written
      expect(TestUser.count).to eq(2)
      expect(TestUser.pluck(:name)).to include('User 1 (copied)', 'User 2 (copied)')
    end

    it 'handles batch operations efficiently' do
      source = ActiveDataFlow::Source::ActiveRecord.new(
        model_name: 'TestUser',
        batch_size: 2,
        order: 'id ASC'
      )

      sink = ActiveDataFlow::Sink::ActiveRecord.new(
        model_name: 'TestUser',
        batch_size: 2,
        upsert: true,
        unique_by: :email
      )

      # Read and transform
      records = []
      source.each do |record|
        records << {
          name: "Updated #{record.name}",
          email: record.email
        }
      end

      # Write with upsert
      records.each { |record| sink.write(record) }
      sink.close

      # Verify upsert worked
      expect(TestUser.count).to eq(3)
      expect(TestUser.pluck(:name)).to all(start_with('Updated'))
    end
  end

  describe 'filtering and transformation' do
    it 'filters source data and writes subset' do
      source = ActiveDataFlow::Source::ActiveRecord.new(
        model_name: 'TestUser',
        where: "name LIKE '%1%' OR name LIKE '%2%'",
        order: 'name ASC'
      )

      records = []
      source.each { |record| records << record }

      expect(records.size).to eq(2)
      expect(records.map(&:name)).to eq(['User 1', 'User 2'])
    end
  end
end
