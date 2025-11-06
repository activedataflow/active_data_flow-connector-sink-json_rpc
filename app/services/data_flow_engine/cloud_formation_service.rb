require 'aws-sdk-cloudformation'
require 'json'

module DataFlowEngine
  class CloudFormationService
    attr_reader :data_flow

    def initialize(data_flow)
      @data_flow = data_flow
      @client = Aws::CloudFormation::Client.new
    end

    # Create CloudFormation stack
    def create_stack(template = nil)
      stack_template = template || generate_template

      response = @client.create_stack({
        stack_name: stack_name,
        template_body: stack_template.to_json,
        capabilities: ['CAPABILITY_IAM', 'CAPABILITY_NAMED_IAM'],
        tags: [
          {
            key: 'ManagedBy',
            value: 'ActiveDataFlow'
          },
          {
            key: 'DataFlow',
            value: data_flow.name
          }
        ]
      })

      wait_for_stack_completion(response.stack_id)

      {
        success: true,
        stack_id: response.stack_id,
        stack_name: stack_name
      }
    rescue Aws::CloudFormation::Errors::ServiceError => e
      { success: false, error: e.message }
    end

    # Update CloudFormation stack
    def update_stack(template = nil)
      stack_template = template || generate_template

      response = @client.update_stack({
        stack_name: stack_name,
        template_body: stack_template.to_json,
        capabilities: ['CAPABILITY_IAM', 'CAPABILITY_NAMED_IAM']
      })

      wait_for_stack_completion(response.stack_id)

      {
        success: true,
        stack_id: response.stack_id
      }
    rescue Aws::CloudFormation::Errors::ServiceError => e
      if e.message.include?('No updates are to be performed')
        { success: true, message: 'No updates needed' }
      else
        { success: false, error: e.message }
      end
    end

    # Delete CloudFormation stack
    def delete_stack
      @client.delete_stack({
        stack_name: stack_name
      })

      {
        success: true,
        message: "Stack #{stack_name} deletion initiated"
      }
    rescue Aws::CloudFormation::Errors::ServiceError => e
      { success: false, error: e.message }
    end

    # Get stack status
    def get_stack_status
      response = @client.describe_stacks({
        stack_name: stack_name
      })

      stack = response.stacks.first

      {
        success: true,
        status: stack.stack_status,
        stack_info: {
          stack_id: stack.stack_id,
          stack_name: stack.stack_name,
          creation_time: stack.creation_time,
          stack_status: stack.stack_status,
          outputs: stack.outputs.map { |o| { key: o.output_key, value: o.output_value } }
        }
      }
    rescue Aws::CloudFormation::Errors::ServiceError => e
      { success: false, error: e.message }
    end

    # Get stack outputs
    def get_stack_outputs
      response = @client.describe_stacks({
        stack_name: stack_name
      })

      stack = response.stacks.first
      outputs = {}

      stack.outputs.each do |output|
        outputs[output.output_key] = output.output_value
      end

      {
        success: true,
        outputs: outputs
      }
    rescue Aws::CloudFormation::Errors::ServiceError => e
      { success: false, error: e.message }
    end

    private

    # Generate CloudFormation template from DataFlow configuration
    def generate_template
      template = {
        'AWSTemplateFormatVersion' => '2010-09-09',
        'Description' => "DataFlow: #{data_flow.name}",
        'Resources' => {},
        'Outputs' => {}
      }

      # Add Lambda resources
      data_flow.lambda_configurations.each_with_index do |lambda_config, index|
        add_lambda_resources(template, lambda_config, index)
      end

      # Add Kafka resources
      data_flow.kafka_configurations.each_with_index do |kafka_config, index|
        add_kafka_resources(template, kafka_config, index)
      end

      # Add API Gateway resources
      data_flow.api_gateway_configurations.each_with_index do |api_config, index|
        add_api_gateway_resources(template, api_config, index)
      end

      template
    end

    # Add Lambda function to template
    def add_lambda_resources(template, lambda_config, index)
      resource_name = "LambdaFunction#{index}"

      template['Resources'][resource_name] = {
        'Type' => 'AWS::Lambda::Function',
        'Properties' => {
          'FunctionName' => lambda_config.function_name,
          'Runtime' => lambda_config.runtime,
          'Handler' => lambda_config.handler,
          'Role' => { 'Fn::GetAtt' => ["LambdaExecutionRole#{index}", 'Arn'] },
          'Code' => {
            'ZipFile' => lambda_config.function_code || 'def handler(event, context); end'
          },
          'MemorySize' => lambda_config.memory_size,
          'Timeout' => lambda_config.timeout,
          'Environment' => {
            'Variables' => lambda_config.environment_variables
          }
        }
      }

      # Add execution role
      template['Resources']["LambdaExecutionRole#{index}"] = {
        'Type' => 'AWS::IAM::Role',
        'Properties' => {
          'AssumeRolePolicyDocument' => {
            'Version' => '2012-10-17',
            'Statement' => [
              {
                'Effect' => 'Allow',
                'Principal' => { 'Service' => 'lambda.amazonaws.com' },
                'Action' => 'sts:AssumeRole'
              }
            ]
          },
          'ManagedPolicyArns' => [
            'arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole'
          ]
        }
      }

      # Add output
      template['Outputs']["#{resource_name}Arn"] = {
        'Value' => { 'Fn::GetAtt' => [resource_name, 'Arn'] },
        'Description' => "ARN of #{lambda_config.function_name}"
      }
    end

    # Add Kafka cluster to template
    def add_kafka_resources(template, kafka_config, index)
      # MSK clusters are complex and typically require VPC setup
      # This is a simplified version
      resource_name = "MSKCluster#{index}"

      template['Resources'][resource_name] = {
        'Type' => 'AWS::MSK::Cluster',
        'Properties' => {
          'ClusterName' => kafka_config.cluster_name,
          'KafkaVersion' => kafka_config.broker_configuration['kafka_version'] || '3.5.1',
          'NumberOfBrokerNodes' => kafka_config.broker_configuration['number_of_broker_nodes'] || 3,
          'BrokerNodeGroupInfo' => {
            'InstanceType' => kafka_config.broker_configuration['instance_type'] || 'kafka.m5.large',
            'ClientSubnets' => { 'Ref' => 'SubnetIds' },
            'SecurityGroups' => { 'Ref' => 'SecurityGroupIds' }
          }
        }
      }

      template['Outputs']["#{resource_name}Arn"] = {
        'Value' => { 'Ref' => resource_name },
        'Description' => "ARN of #{kafka_config.cluster_name}"
      }
    end

    # Add API Gateway to template
    def add_api_gateway_resources(template, api_config, index)
      resource_name = "HttpApi#{index}"

      template['Resources'][resource_name] = {
        'Type' => 'AWS::ApiGatewayV2::Api',
        'Properties' => {
          'Name' => api_config.api_name,
          'ProtocolType' => 'HTTP',
          'Description' => "API for #{data_flow.name}"
        }
      }

      # Add stage
      template['Resources']["#{resource_name}Stage"] = {
        'Type' => 'AWS::ApiGatewayV2::Stage',
        'Properties' => {
          'ApiId' => { 'Ref' => resource_name },
          'StageName' => api_config.stage_name,
          'AutoDeploy' => true
        }
      }

      template['Outputs']["#{resource_name}Endpoint"] = {
        'Value' => { 'Fn::GetAtt' => [resource_name, 'ApiEndpoint'] },
        'Description' => "Endpoint for #{api_config.api_name}"
      }
    end

    # Stack name based on data flow
    def stack_name
      "activedataflow-#{data_flow.name.parameterize}"
    end

    # Wait for stack operation to complete
    def wait_for_stack_completion(stack_id)
      @client.wait_until(:stack_create_complete, stack_name: stack_id) do |w|
        w.max_attempts = 60
        w.delay = 10
      end
    rescue Aws::Waiters::Errors::WaiterFailed => e
      Rails.logger.error("Stack operation failed: #{e.message}")
    end
  end
end
