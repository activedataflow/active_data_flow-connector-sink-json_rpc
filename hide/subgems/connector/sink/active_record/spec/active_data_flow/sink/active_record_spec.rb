# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveDataFlow::Sink::ActiveRecord do
  let(:config) { { model_name: 'TestUser' } }
  let(:sink) { described_class.new(config) }

  describe '#initialize' do
    it 'accepts configuration hash' do
      expect(sink.config).to eq(config)
    end

    it 'initializes empty buffer' do
      expect(sink.buffer).to eq([])
    end

    context 'when model_name is missing' do
      let(:config) { {} }

      it 'raises ArgumentError' do
        expect { sink }.to raise_error(ArgumentError, 'model_name is required')
      end
    end
  end

  describe '#resolve_model' do
    it 'converts string to class' do
      expect(sink.send(:resolve_model)).to eq(TestUser)
    end

    it 'caches the model class' do
      first_call = sink.send(:resolve_model)
      second_call = sink.send(:resolve_model)
      expect(first_call).to be(second_call)
    end

    context 'with invalid model name' do
      let(:config) { { model_name: 'NonExistentModel' } }

      it 'raises ArgumentError' do
        expect { sink.send(:resolve_model) }.to raise_error(ArgumentError, /Invalid model name/)
      end
    end

    context 'with namespaced model' do
      before do
        module TestNamespace
          class NamespacedUser < ActiveRecord::Base
            self.table_name = 'test_users'
          end
        end
      end

      let(:config) { { model_name: 'TestNamespace::NamespacedUser' } }

      it 'resolves namespaced model' do
        expect(sink.send(:resolve_model)).to eq(TestNamespace::NamespacedUser)
      end
    end
  end

  describe '#write_single' do
    let(:record) { { name: 'John Doe', email: 'john@example.com' } }

    it 'creates a record successfully' do
      expect { sink.send(:write_single, record) }.to change(TestUser, :count).by(1)
    end

    it 'creates record with correct attributes' do
      sink.send(:write_single, record)
      user = TestUser.last
      expect(user.name).to eq('John Doe')
      expect(user.email).to eq('john@example.com')
    end

    context 'with validation errors' do
      let(:record) { { name: '', email: '' } }

      it 'raises ActiveRecord::RecordInvalid' do
        expect { sink.send(:write_single, record) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'with skip_validations option' do
      let(:config) { { model_name: 'TestUser', skip_validations: true } }
      let(:record) { { name: '', email: '' } }

      it 'inserts record without validation' do
        expect { sink.send(:write_single, record) }.to change(TestUser, :count).by(1)
      end
    end
  end

  describe 'batch writing' do
    let(:config) { { model_name: 'TestUser', batch_size: 3 } }
    let(:records) do
      [
        { name: 'User 1', email: 'user1@example.com' },
        { name: 'User 2', email: 'user2@example.com' },
        { name: 'User 3', email: 'user3@example.com' }
      ]
    end

    describe '#write with buffering' do
      it 'buffers records until batch_size is reached' do
        sink.write(records[0])
        sink.write(records[1])
        expect(sink.buffer.size).to eq(2)
        expect(TestUser.count).to eq(0)
      end

      it 'automatically flushes when buffer reaches batch_size' do
        records.each { |record| sink.write(record) }
        expect(sink.buffer).to be_empty
        expect(TestUser.count).to eq(3)
      end

      it 'keeps remaining records in buffer after partial flush' do
        4.times do |i|
          sink.write({ name: "User #{i}", email: "user#{i}@example.com" })
        end
        expect(sink.buffer.size).to eq(1)
        expect(TestUser.count).to eq(3)
      end
    end

    describe '#flush' do
      it 'writes all buffered records' do
        records.each { |record| sink.write(record) }
        sink.flush
        expect(TestUser.count).to eq(3)
      end

      it 'clears the buffer after flushing' do
        sink.write(records[0])
        sink.write(records[1])
        sink.flush
        expect(sink.buffer).to be_empty
      end

      it 'does nothing when buffer is empty' do
        expect { sink.flush }.not_to change(TestUser, :count)
      end
    end

    describe '#close' do
      it 'flushes remaining records' do
        sink.write(records[0])
        sink.write(records[1])
        expect { sink.close }.to change(TestUser, :count).by(2)
      end

      it 'clears the buffer' do
        sink.write(records[0])
        sink.close
        expect(sink.buffer).to be_empty
      end
    end

    describe '#write_batch' do
      it 'uses insert_all for batch inserts' do
        expect(TestUser).to receive(:insert_all).with(records)
        sink.send(:write_batch, records)
      end

      it 'inserts all records in one operation' do
        expect { sink.send(:write_batch, records) }.to change(TestUser, :count).by(3)
      end
    end
  end

  describe 'upsert functionality' do
    let(:config) { { model_name: 'TestUser', batch_size: 2, upsert: true, unique_by: :email } }
    let(:records) do
      [
        { name: 'User 1', email: 'user1@example.com' },
        { name: 'User 2', email: 'user2@example.com' }
      ]
    end

    describe '#write_batch with upsert' do
      it 'uses upsert_all when upsert is enabled' do
        expect(TestUser).to receive(:upsert_all).with(records, unique_by: :email)
        sink.send(:write_batch, records)
      end

      it 'inserts new records' do
        expect { sink.send(:write_batch, records) }.to change(TestUser, :count).by(2)
      end

      it 'updates existing records on conflict' do
        TestUser.create!(name: 'Old Name', email: 'user1@example.com')
        sink.send(:write_batch, records)
        user = TestUser.find_by(email: 'user1@example.com')
        expect(user.name).to eq('User 1')
      end

      context 'with update_only option' do
        let(:config) do
          {
            model_name: 'TestUser',
            batch_size: 2,
            upsert: true,
            unique_by: :email,
            update_only: [:name]
          }
        end

        it 'passes update_only to upsert_all' do
          expect(TestUser).to receive(:upsert_all).with(records, unique_by: :email, update_only: [:name])
          sink.send(:write_batch, records)
        end
      end

      context 'without unique_by' do
        let(:config) { { model_name: 'TestUser', batch_size: 2, upsert: true } }

        it 'calls upsert_all without unique_by' do
          expect(TestUser).to receive(:upsert_all).with(records)
          sink.send(:write_batch, records)
        end
      end
    end

    describe 'conflict handling' do
      before do
        TestUser.create!(name: 'Existing User', email: 'user1@example.com')
      end

      it 'handles conflicts gracefully' do
        expect { sink.send(:write_batch, records) }.not_to raise_error
      end

      it 'updates conflicting record' do
        sink.send(:write_batch, records)
        expect(TestUser.count).to eq(2)
        user = TestUser.find_by(email: 'user1@example.com')
        expect(user.name).to eq('User 1')
      end
    end
  end

  describe 'transaction management' do
    let(:config) { { model_name: 'TestUser', batch_size: 2, transaction: true } }
    let(:records) do
      [
        { name: 'User 1', email: 'user1@example.com' },
        { name: 'User 2', email: 'user2@example.com' }
      ]
    end

    describe '#execute_in_transaction' do
      it 'wraps operations in transaction when enabled' do
        expect(TestUser).to receive(:transaction).and_call_original
        sink.send(:write_batch, records)
      end

      it 'commits transaction on success' do
        expect { sink.send(:write_batch, records) }.to change(TestUser, :count).by(2)
      end

      it 'rolls back transaction on error' do
        allow(TestUser).to receive(:insert_all).and_raise(StandardError, 'Test error')
        expect { sink.send(:write_batch, records) }.to raise_error(StandardError)
        expect(TestUser.count).to eq(0)
      end

      context 'without transaction mode' do
        let(:config) { { model_name: 'TestUser', batch_size: 2 } }

        it 'does not wrap in transaction' do
          expect(TestUser).not_to receive(:transaction)
          sink.send(:write_batch, records)
        end
      end
    end
  end
end
