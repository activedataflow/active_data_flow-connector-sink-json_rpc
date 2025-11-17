# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveDataFlow::Source::ActiveRecord do
  let(:config) { { model_name: 'TestUser' } }
  let(:source) { described_class.new(config) }

  before do
    TestUser.create!(name: 'User 1', email: 'user1@example.com')
    TestUser.create!(name: 'User 2', email: 'user2@example.com')
    TestUser.create!(name: 'User 3', email: 'user3@example.com')
  end

  describe '#initialize' do
    it 'accepts configuration hash' do
      expect(source.config).to eq(config)
    end

    context 'when model_name is missing' do
      let(:config) { {} }

      it 'raises ArgumentError' do
        expect { source }.to raise_error(ArgumentError, 'model_name is required')
      end
    end
  end

  describe '#resolve_model' do
    it 'converts string to class' do
      expect(source.send(:resolve_model)).to eq(TestUser)
    end

    it 'caches the model class' do
      first_call = source.send(:resolve_model)
      second_call = source.send(:resolve_model)
      expect(first_call).to be(second_call)
    end

    context 'with invalid model name' do
      let(:config) { { model_name: 'NonExistentModel' } }

      it 'raises ArgumentError' do
        expect { source.send(:resolve_model) }.to raise_error(ArgumentError, /Invalid model name/)
      end
    end
  end

  describe '#build_query' do
    it 'builds basic query' do
      query = source.send(:build_query)
      expect(query.to_a.size).to eq(3)
    end

    context 'with where clause' do
      let(:config) { { model_name: 'TestUser', where: { name: 'User 1' } } }

      it 'filters records' do
        query = source.send(:build_query)
        expect(query.to_a.size).to eq(1)
        expect(query.first.name).to eq('User 1')
      end
    end

    context 'with order clause' do
      let(:config) { { model_name: 'TestUser', order: 'name DESC' } }

      it 'orders records' do
        query = source.send(:build_query)
        names = query.pluck(:name)
        expect(names).to eq(['User 3', 'User 2', 'User 1'])
      end
    end

    context 'with limit' do
      let(:config) { { model_name: 'TestUser', limit: 2 } }

      it 'limits records' do
        query = source.send(:build_query)
        expect(query.to_a.size).to eq(2)
      end
    end

    context 'with select' do
      let(:config) { { model_name: 'TestUser', select: [:name] } }

      it 'selects specific columns' do
        query = source.send(:build_query)
        record = query.first
        expect(record.name).to eq('User 1')
      end
    end

    context 'with readonly' do
      let(:config) { { model_name: 'TestUser', readonly: true } }

      it 'marks records as readonly' do
        query = source.send(:build_query)
        record = query.first
        expect(record).to be_readonly
      end
    end

    context 'with readonly false' do
      let(:config) { { model_name: 'TestUser', readonly: false } }

      it 'does not mark records as readonly' do
        query = source.send(:build_query)
        record = query.first
        expect(record).not_to be_readonly
      end
    end
  end

  describe '#each' do
    it 'yields all records' do
      records = []
      source.each { |record| records << record }
      expect(records.size).to eq(3)
    end

    it 'yields TestUser instances' do
      source.each do |record|
        expect(record).to be_a(TestUser)
      end
    end

    context 'with empty result set' do
      let(:config) { { model_name: 'TestUser', where: { name: 'NonExistent' } } }

      it 'does not yield any records' do
        records = []
        source.each { |record| records << record }
        expect(records).to be_empty
      end
    end
  end

  describe 'batch reading' do
    context 'with batch_size' do
      let(:config) { { model_name: 'TestUser', batch_size: 2 } }

      it 'yields all records' do
        records = []
        source.each { |record| records << record }
        expect(records.size).to eq(3)
      end

      it 'processes records in batches' do
        records = []
        source.each { |record| records << record }
        expect(records.size).to eq(3)
        expect(records.all? { |r| r.is_a?(TestUser) }).to be true
      end
    end

    context 'without batch_size' do
      it 'yields all records' do
        records = []
        source.each { |record| records << record }
        expect(records.size).to eq(3)
      end
    end
  end

  describe '#close' do
    it 'does not raise error' do
      expect { source.close }.not_to raise_error
    end
  end
end
