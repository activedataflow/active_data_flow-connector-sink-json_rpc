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

  describe 'integration: multi-stage pipeline' do
    let(:source_connector) { double('source_connector') }
    let(:sink_connector) { double('sink_connector') }

    let(:source_stage_class) do
      Class.new(FunctionalTaskSupervisor::Stage) do
        def perform_work
          records = connector.fetch
          Success(data: records)
        end
      end
    end

    let(:transform_stage_class) do
      Class.new(FunctionalTaskSupervisor::Stage) do
        attr_accessor :input_records

        def perform_work
          transformed = input_records.map { |r| r.merge(transformed: true) }
          Success(data: transformed)
        end
      end
    end

    let(:sink_stage_class) do
      Class.new(FunctionalTaskSupervisor::Stage) do
        attr_accessor :input_records

        def perform_work
          count = connector.write(input_records)
          Success(data: { records_written: count })
        end
      end
    end

    after do
      source_stage_class.instance = nil
      sink_stage_class.instance = nil
    end

    it 'executes a complete source -> transform -> sink pipeline' do
      # Setup connectors
      source_data = [{ id: 1, name: 'Alice' }, { id: 2, name: 'Bob' }]
      allow(source_connector).to receive(:fetch).and_return(source_data)
      allow(sink_connector).to receive(:write).and_return(2)

      source_stage_class.instance = source_connector
      sink_stage_class.instance = sink_connector

      # Create stages
      source = source_stage_class.new('source')
      transform = transform_stage_class.new('transform')
      sink = sink_stage_class.new('sink')

      # Execute pipeline
      source.execute
      expect(source).to be_success

      transform.input_records = source.value[:data]
      transform.execute
      expect(transform).to be_success
      expect(transform.value[:data]).to eq([
        { id: 1, name: 'Alice', transformed: true },
        { id: 2, name: 'Bob', transformed: true }
      ])

      sink.input_records = transform.value[:data]
      sink.execute
      expect(sink).to be_success
      expect(sink.value[:data]).to eq({ records_written: 2 })

      # Verify connector interactions
      expect(source_connector).to have_received(:fetch).once
      expect(sink_connector).to have_received(:write).with([
        { id: 1, name: 'Alice', transformed: true },
        { id: 2, name: 'Bob', transformed: true }
      ])
    end

    it 'handles errors in the pipeline gracefully' do
      allow(source_connector).to receive(:fetch).and_raise(StandardError, 'Connection failed')
      source_stage_class.instance = source_connector

      source = source_stage_class.new('source')
      source.execute

      expect(source).to be_failure
      expect(source.error[:error]).to eq('Connection failed')
    end

    it 'allows pipeline to short-circuit on failure' do
      allow(source_connector).to receive(:fetch).and_raise(StandardError, 'Database error')
      source_stage_class.instance = source_connector

      source = source_stage_class.new('source')
      transform = transform_stage_class.new('transform')
      sink = sink_stage_class.new('sink')

      # Execute with short-circuit on failure
      source.execute

      unless source.success?
        # Pipeline stops here
        expect(transform).not_to be_performed
        expect(sink).not_to be_performed
      end

      expect(source).to be_failure
    end

    it 'works with Task orchestration' do
      source_data = [{ id: 1 }]
      allow(source_connector).to receive(:fetch).and_return(source_data)
      source_stage_class.instance = source_connector

      # Create a simple stage that doesn't need input wiring
      simple_stage_class = Class.new(FunctionalTaskSupervisor::Stage) do
        def perform_work
          Success(data: connector.fetch)
        end
      end
      simple_stage_class.instance = source_connector

      task = FunctionalTaskSupervisor::Task.new
      stage1 = simple_stage_class.new('fetch1')
      stage2 = simple_stage_class.new('fetch2')
      task.add_stage(stage1)
      task.add_stage(stage2)

      result = task.run

      expect(result).to be_success
      expect(stage1).to be_success
      expect(stage2).to be_success
      expect(task.stages.length).to eq(2)

      # Cleanup
      simple_stage_class.instance = nil
    end
  end

  describe 'integration: connector lifecycle' do
    it 'allows connector to be replaced between runs' do
      connector_v1 = double('connector_v1', fetch: ['v1_data'])
      connector_v2 = double('connector_v2', fetch: ['v2_data'])

      test_stage_class.instance = connector_v1
      stage1 = test_stage_class.new('run1')
      stage1.execute
      expect(stage1.value[:data]).to eq(['v1_data'])

      # Replace connector
      test_stage_class.instance = connector_v2
      stage2 = test_stage_class.new('run2')
      stage2.execute
      expect(stage2.value[:data]).to eq(['v2_data'])
    end

    it 'shares connector instance across multiple stage instances' do
      call_count = 0
      connector = double('connector')
      allow(connector).to receive(:fetch) { call_count += 1; ["call_#{call_count}"] }

      test_stage_class.instance = connector

      stage1 = test_stage_class.new('stage1')
      stage2 = test_stage_class.new('stage2')

      stage1.execute
      stage2.execute

      expect(stage1.value[:data]).to eq(['call_1'])
      expect(stage2.value[:data]).to eq(['call_2'])
      expect(call_count).to eq(2)
    end
  end
end
