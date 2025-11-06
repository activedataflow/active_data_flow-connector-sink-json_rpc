Given('the ActiveDataFlow engine is mounted at {string}') do |path|
  @base_path = path
end

Given('the following data flows exist:') do |table|
  table.hashes.each do |row|
    create(:data_flow, row)
  end
end

Given('a data flow named {string} exists') do |name|
  @data_flow = create(:data_flow, name: name)
end

Given('a data flow named {string} exists with Lambda configuration') do |name|
  @data_flow = create(:data_flow, :with_lambda, name: name)
end

Given('a data flow named {string} exists with deployed Lambda') do |name|
  @data_flow = create(:data_flow, :with_lambda, name: name)
  @data_flow.lambda_configurations.first.update(
    aws_function_arn: 'arn:aws:lambda:us-east-1:123456789012:function:test',
    aws_version: '$LATEST'
  )
end

When('I send a GET request to {string}') do |path|
  get "#{@base_path}#{path}"
  @response = last_response
end

When('I send a POST request to {string}') do |path|
  post "#{@base_path}#{path}"
  @response = last_response
end

When('I send a POST request to {string} with:') do |path, body|
  post "#{@base_path}#{path}", body, { 'CONTENT_TYPE' => 'application/json' }
  @response = last_response
end

Then('the response status should be {int}') do |status|
  expect(@response.status).to eq(status)
end

Then('the JSON response should contain {int} data flows') do |count|
  json = JSON.parse(@response.body)
  expect(json['data_flows'].length).to eq(count)
end

Then('the JSON response should have {string} with value {string}') do |key, value|
  json = JSON.parse(@response.body)
  expect(json['data_flow'][key]).to eq(value)
end

Then('the data flow {string} should have sync status {string}') do |name, status|
  data_flow = DataFlowEngine::DataFlow.find_by(name: name)
  expect(data_flow.aws_sync_status).to eq(status)
end

Then('the data flow {string} should be updated with AWS configuration') do |name|
  data_flow = DataFlowEngine::DataFlow.find_by(name: name)
  expect(data_flow.last_synced_at).not_to be_nil
end

Then('the JSON response should include sync status information') do
  json = JSON.parse(@response.body)
  expect(json['status']).to include('name', 'status', 'aws_sync_status')
end
