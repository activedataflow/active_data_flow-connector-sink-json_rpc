FactoryBot.define do
  factory :data_flow, class: 'DataFlowEngine::DataFlow' do
    sequence(:name) { |n| "test_flow_#{n}" }
    description { "Test data flow" }
    status { 'draft' }
    aws_sync_status { 'not_synced' }
    configuration { {} }
    metadata { {} }

    trait :active do
      status { 'active' }
    end

    trait :synced do
      aws_sync_status { 'synced' }
      last_synced_at { Time.current }
    end

    trait :with_lambda do
      after(:create) do |data_flow|
        create(:lambda_configuration, data_flow: data_flow)
      end
    end

    trait :with_kafka do
      after(:create) do |data_flow|
        create(:kafka_configuration, data_flow: data_flow)
      end
    end

    trait :with_api_gateway do
      after(:create) do |data_flow|
        create(:api_gateway_configuration, data_flow: data_flow)
      end
    end
  end

  factory :lambda_configuration, class: 'DataFlowEngine::LambdaConfiguration' do
    association :data_flow
    sequence(:function_name) { |n| "test_function_#{n}" }
    function_code { "def handler(event:, context:); end" }
    code_language { 'ruby' }
    runtime { 'ruby3.2' }
    handler { 'handler.process' }
    memory_size { 512 }
    timeout { 30 }
    environment_variables { {} }

    trait :deployed do
      aws_function_arn { "arn:aws:lambda:us-east-1:123456789012:function:#{function_name}" }
      aws_version { '$LATEST' }
    end

    trait :go_language do
      code_language { 'go' }
      runtime { 'provided.al2023' }
      handler { 'bootstrap' }
    end

    trait :rust_language do
      code_language { 'rust' }
      runtime { 'provided.al2023' }
      handler { 'bootstrap' }
    end
  end

  factory :kafka_configuration, class: 'DataFlowEngine::KafkaConfiguration' do
    association :data_flow
    sequence(:cluster_name) { |n| "test_cluster_#{n}" }
    topics { ['test.topic.1', 'test.topic.2'] }
    broker_configuration do
      {
        'instance_type' => 'kafka.m5.large',
        'number_of_broker_nodes' => 3,
        'kafka_version' => '3.5.1'
      }
    end

    trait :deployed do
      cluster_arn { "arn:aws:kafka:us-east-1:123456789012:cluster/#{cluster_name}" }
    end
  end

  factory :api_gateway_configuration, class: 'DataFlowEngine::ApiGatewayConfiguration' do
    association :data_flow
    sequence(:api_name) { |n| "test_api_#{n}" }
    stage_name { 'production' }
    routes do
      [
        {
          'route_key' => 'GET /test',
          'integration_type' => 'AWS_PROXY'
        }
      ]
    end

    trait :deployed do
      api_id { SecureRandom.hex(5) }
      endpoint_url { "https://#{api_id}.execute-api.us-east-1.amazonaws.com" }
    end
  end
end
