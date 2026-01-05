# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveDataFlow::Connector::Sink::JsonRpcSink do
  let(:url) { 'http://localhost:8999' }
  let(:sink) { described_class.new(url: url, batch_size: 10) }

  describe '#initialize' do
    it 'creates a new JSON-RPC sink with URL and batch size' do
      expect(sink.url).to eq(url)
      expect(sink.batch_size).to eq(10)
      expect(sink.client_wrapper).to be_a(ActiveDataFlow::Connector::JsonRpc::ClientWrapper)
    end

    it 'accepts custom client options' do
      custom_sink = described_class.new(
        url: url,
        batch_size: 10,
        client_options: { timeout: 60 }
      )
      
      expect(custom_sink).to be_a(described_class)
    end
  end

  describe '#write' do
    it 'sends a single record to the server' do
      record = { name: 'John Doe', email: 'john@example.com' }
      
      allow(sink.client_wrapper).to receive(:send_record).with(record).and_return(
        { status: 'success', message: 'Record received' }
      )
      
      response = sink.write(record)
      expect(response[:status]).to eq('success')
    end

    it 'handles errors gracefully' do
      record = { name: 'John' }
      
      allow(sink.client_wrapper).to receive(:send_record).and_return(
        { status: 'error', message: 'Connection failed' }
      )
      
      response = sink.write(record)
      expect(response[:status]).to eq('error')
    end
  end

  describe '#write_batch' do
    it 'sends multiple records to the server' do
      records = [
        { name: 'Alice', email: 'alice@example.com' },
        { name: 'Bob', email: 'bob@example.com' }
      ]
      
      allow(sink.client_wrapper).to receive(:send_records).with(records).and_return(
        { status: 'success', message: '2 records received' }
      )
      
      response = sink.write_batch(records)
      expect(response[:status]).to eq('success')
    end

    it 'handles empty record arrays' do
      response = sink.write_batch([])
      expect(response[:status]).to eq('success')
      expect(response[:message]).to include('No records')
    end
  end

  describe '#buffer_write' do
    it 'buffers records until batch size is reached' do
      allow(sink.client_wrapper).to receive(:send_records).and_return(
        { status: 'success', message: 'Records received' }
      )
      
      # Write 9 records (below batch size of 10)
      9.times { |i| sink.buffer_write({ id: i }) }
      expect(sink.buffer_size).to eq(9)
      
      # 10th record should trigger flush
      response = sink.buffer_write({ id: 9 })
      expect(response).not_to be_nil
      expect(response[:status]).to eq('success')
      expect(sink.buffer_size).to eq(0)
    end
  end

  describe '#flush' do
    it 'flushes buffered records' do
      allow(sink.client_wrapper).to receive(:send_records).and_return(
        { status: 'success', message: 'Records received' }
      )
      
      3.times { |i| sink.buffer_write({ id: i }) }
      expect(sink.buffer_size).to eq(3)
      
      response = sink.flush
      expect(response[:status]).to eq('success')
      expect(sink.buffer_size).to eq(0)
    end

    it 'returns nil when buffer is empty' do
      response = sink.flush
      expect(response).to be_nil
    end
  end

  describe '#close' do
    it 'flushes remaining records on close' do
      allow(sink.client_wrapper).to receive(:send_records).and_return(
        { status: 'success', message: 'Records received' }
      )
      
      2.times { |i| sink.buffer_write({ id: i }) }
      expect(sink.buffer_size).to eq(2)
      
      sink.close
      expect(sink.buffer_size).to eq(0)
    end
  end

  describe '#test_connection' do
    it 'tests connection to server' do
      allow(sink.client_wrapper).to receive(:test_connection).and_return(true)
      
      expect(sink.test_connection).to be true
    end
  end

  describe '#health_check' do
    it 'retrieves server health status' do
      allow(sink.client_wrapper).to receive(:health_check).and_return(
        { status: 'ok', queue_size: 0, timestamp: Time.now.iso8601 }
      )
      
      health = sink.health_check
      expect(health[:status]).to eq('ok')
    end
  end

  describe '#buffer_size' do
    it 'returns the current buffer size' do
      expect(sink.buffer_size).to eq(0)
      
      sink.buffer_write({ id: 1 })
      expect(sink.buffer_size).to eq(1)
    end
  end

  describe '.from_json' do
    it 'deserializes from JSON' do
      data = {
        "url" => url,
        "batch_size" => 50,
        "client_options" => {}
      }
      
      deserialized = described_class.from_json(data)
      expect(deserialized.url).to eq(url)
      expect(deserialized.batch_size).to eq(50)
    end
  end
end
