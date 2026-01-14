# frozen_string_literal: true

require 'bundler/setup'
require 'functional_task_supervisor'
require 'active_data_flow/stage_extensions'

RSpec.describe 'FunctionalTaskSupervisor::Stage extensions' do
  # Create test stage classes to avoid polluting the base class
  let(:test_stage_class) do
    Class.new(FunctionalTaskSupervisor::Stage) do
      def perform_work
        Success(data: connector&.fetch)
      end
    end
  end

  let(:another_stage_class) do
    Class.new(FunctionalTaskSupervisor::Stage)
  end

  after do
    # Clean up class-level instances
    test_stage_class.instance = nil
    another_stage_class.instance = nil
  end

  describe '.instance=' do
    it 'stores an instance at the class level' do
      connector = double('connector')
      test_stage_class.instance = connector

      expect(test_stage_class.instance).to eq(connector)
    end

    it 'allows nil to be set' do
      test_stage_class.instance = double('connector')
      test_stage_class.instance = nil

      expect(test_stage_class.instance).to be_nil
    end

    it 'isolates instances between different stage subclasses' do
      connector1 = double('connector1')
      connector2 = double('connector2')

      test_stage_class.instance = connector1
      another_stage_class.instance = connector2

      expect(test_stage_class.instance).to eq(connector1)
      expect(another_stage_class.instance).to eq(connector2)
    end
  end

  describe '.instance' do
    it 'returns nil when no instance is set' do
      expect(test_stage_class.instance).to be_nil
    end

    it 'returns the stored instance' do
      connector = double('connector')
      test_stage_class.instance = connector

      expect(test_stage_class.instance).to eq(connector)
    end
  end

  describe '#connector' do
    it 'returns the class-level instance' do
      connector = double('connector')
      test_stage_class.instance = connector

      stage = test_stage_class.new('test')

      expect(stage.connector).to eq(connector)
    end

    it 'returns nil when no instance is set' do
      stage = test_stage_class.new('test')

      expect(stage.connector).to be_nil
    end

    it 'returns the correct instance for each stage subclass' do
      connector1 = double('connector1')
      connector2 = double('connector2')

      test_stage_class.instance = connector1
      another_stage_class.instance = connector2

      stage1 = test_stage_class.new('stage1')
      stage2 = another_stage_class.new('stage2')

      expect(stage1.connector).to eq(connector1)
      expect(stage2.connector).to eq(connector2)
    end
  end

  describe 'integration with perform_work' do
    it 'allows connector to be used in perform_work' do
      connector = double('connector', fetch: [{ id: 1 }, { id: 2 }])
      test_stage_class.instance = connector

      stage = test_stage_class.new('test')
      result = stage.execute

      expect(result).to be_success
      expect(result.value![:data]).to eq([{ id: 1 }, { id: 2 }])
    end

    it 'handles nil connector gracefully' do
      stage = test_stage_class.new('test')
      result = stage.execute

      expect(result).to be_success
      expect(result.value![:data]).to be_nil
    end
  end
end
