# frozen_string_literal: true

Given('a JSON-RPC sink connector') do
  @sink = ActiveDataFlow::Connector::Sink::JsonRpcSink.new(
    url: 'http://localhost:8999',
    batch_size: 10
  )
  
  # Mock the client wrapper
  allow(@sink.client_wrapper).to receive(:send_record).and_return(
    { status: 'success', message: 'Record received' }
  )
  allow(@sink.client_wrapper).to receive(:send_records).and_return(
    { status: 'success', message: 'Records received' }
  )
  allow(@sink.client_wrapper).to receive(:test_connection).and_return(true)
  allow(@sink.client_wrapper).to receive(:health_check).and_return(
    { status: 'ok', queue_size: 0, timestamp: Time.now.iso8601 }
  )
end

Given('a JSON-RPC sink connector with batch size {int}') do |batch_size|
  @sink = ActiveDataFlow::Connector::Sink::JsonRpcSink.new(
    url: 'http://localhost:8999',
    batch_size: batch_size
  )
  
  # Mock the client wrapper
  allow(@sink.client_wrapper).to receive(:send_records).and_return(
    { status: 'success', message: 'Records received' }
  )
end

When('I write a single record') do
  @record = { name: 'John Doe', email: 'john@example.com' }
  @response = @sink.write(@record)
end

Then('the record should be sent successfully') do
  expect(@response[:status]).to eq('success')
end

When('I write multiple records in a batch') do
  @records = [
    { name: 'Alice', email: 'alice@example.com' },
    { name: 'Bob', email: 'bob@example.com' }
  ]
  @response = @sink.write_batch(@records)
end

Then('all records should be sent successfully') do
  expect(@response[:status]).to eq('success')
end

When('I buffer {int} records') do |count|
  count.times do |i|
    @sink.buffer_write({ id: i, name: "User #{i}" })
  end
end

Then('the buffer should contain {int} records') do |count|
  expect(@sink.buffer_size).to eq(count)
end

When('I flush the buffer') do
  @flush_response = @sink.flush
end

Then('the buffer should be empty') do
  expect(@sink.buffer_size).to eq(0)
end

Then('the buffer should be automatically flushed') do
  expect(@sink.buffer_size).to eq(0)
end

When('I test the connection') do
  @connection_result = @sink.test_connection
end

Then('the connection test should complete') do
  expect(@connection_result).to be_in([true, false])
end

When('I check the server health') do
  @health_status = @sink.health_check
end

Then('I should receive a health status') do
  expect(@health_status).to be_a(Hash)
  expect(@health_status).to have_key(:status)
end

After do
  @sink&.close
end
