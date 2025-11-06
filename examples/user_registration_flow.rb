# Example DataFlow object
# Place this file in your Rails app at: app/data_flow/user_registration_flow.rb

class UserRegistrationFlow < ActiveDataFlow::DataFlowBase
  configure do |config|
    config.description "Handles user registration events and notifications"
    
    # Lambda function configuration
    config.lambda_function(
      code_language: 'ruby',
      runtime: 'ruby3.2',
      handler: 'handler.process',
      memory_size: 512,
      timeout: 30,
      environment_variables: {
        'NOTIFICATION_QUEUE' => 'user-notifications',
        'EMAIL_SERVICE' => 'ses'
      }
    )
    
    # Kafka topics for event streaming
    config.kafka_topics ['user.registered', 'user.verified', 'user.activated']
    
    # Kafka cluster configuration
    config.kafka_cluster(
      instance_type: 'kafka.m5.large',
      number_of_broker_nodes: 3,
      kafka_version: '3.5.1'
    )
    
    # API Gateway configuration
    config.api_gateway(
      api_name: 'UserRegistrationAPI',
      stage_name: 'production',
      routes: [
        {
          route_key: 'POST /register',
          integration_type: 'AWS_PROXY',
          integration_uri: 'lambda_function_arn'
        },
        {
          route_key: 'GET /status/{userId}',
          integration_type: 'AWS_PROXY',
          integration_uri: 'lambda_function_arn'
        }
      ]
    )
    
    # Additional metadata
    config.metadata(
      owner: 'Platform Team',
      version: '1.0.0',
      documentation: 'https://docs.example.com/user-registration'
    )
  end

  # Controller-like action for processing registrations
  def process
    # This would be called when the DataFlow is triggered
    {
      status: 'success',
      message: 'User registration processed',
      timestamp: Time.current
    }
  end

  # Custom action to check registration status
  def check_status
    {
      flow_status: self.class.data_flow_record.status,
      aws_sync_status: self.class.data_flow_record.aws_sync_status,
      lambda_deployed: self.class.data_flow_record.lambda_configurations.any?(&:deployed?),
      kafka_deployed: self.class.data_flow_record.kafka_configurations.any?(&:deployed?),
      api_deployed: self.class.data_flow_record.api_gateway_configurations.any?(&:deployed?)
    }
  end

  # Custom action to activate the flow
  def activate
    self.class.data_flow_record.activate!
    self.class.push!
    
    {
      status: 'activated',
      message: 'User registration flow activated and pushed to AWS'
    }
  end
end
