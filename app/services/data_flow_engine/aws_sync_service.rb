module DataFlowEngine
  class AwsSyncService
    attr_reader :data_flow

    def initialize(data_flow)
      @data_flow = data_flow
      @errors = []
      @results = {}
    end

    # Push all configurations to AWS
    def push
      validate_credentials
      return error_result('AWS credentials not configured') unless @credentials_valid

      begin
        # Push Lambda configurations
        push_lambda_configurations

        # Push Kafka configurations
        push_kafka_configurations

        # Push API Gateway configurations
        push_api_gateway_configurations

        # Use CloudFormation if template is provided
        push_cloudformation_stack if data_flow.configuration['cloudformation_template'].present?

        if @errors.empty?
          success_result
        else
          partial_success_result
        end
      rescue StandardError => e
        error_result("Sync failed: #{e.message}")
      end
    end

    # Pull all configurations from AWS
    def pull
      validate_credentials
      return error_result('AWS credentials not configured') unless @credentials_valid

      begin
        # Pull Lambda configurations
        pull_lambda_configurations

        # Pull Kafka configurations
        pull_kafka_configurations

        # Pull API Gateway configurations
        pull_api_gateway_configurations

        if @errors.empty?
          success_result
        else
          partial_success_result
        end
      rescue StandardError => e
        error_result("Pull failed: #{e.message}")
      end
    end

    # Bidirectional sync (pull then push)
    def sync
      pull_result = pull
      return pull_result unless pull_result[:success]

      push
    end

    private

    # Validate AWS credentials
    def validate_credentials
      @credentials_valid = ActiveDataFlow.configuration.aws_access_key_id.present? &&
                          ActiveDataFlow.configuration.aws_secret_access_key.present?
    end

    # Push Lambda configurations
    def push_lambda_configurations
      data_flow.lambda_configurations.each do |lambda_config|
        service = LambdaService.new(lambda_config)
        result = service.deploy

        if result[:success]
          @results[:lambda] ||= []
          @results[:lambda] << {
            function_name: lambda_config.function_name,
            function_arn: result[:function_arn],
            status: 'deployed'
          }
        else
          @errors << "Lambda #{lambda_config.function_name}: #{result[:error]}"
        end
      end
    end

    # Pull Lambda configurations
    def pull_lambda_configurations
      data_flow.lambda_configurations.each do |lambda_config|
        next unless lambda_config.deployed?

        service = LambdaService.new(lambda_config)
        result = service.get_function

        if result[:success]
          config = result[:configuration]
          
          lambda_config.update(
            runtime: config[:runtime],
            handler: config[:handler],
            memory_size: config[:memory_size],
            timeout: config[:timeout],
            environment_variables: config[:environment][:variables] || {},
            aws_version: config[:version]
          )

          @results[:lambda] ||= []
          @results[:lambda] << {
            function_name: lambda_config.function_name,
            status: 'synced'
          }
        else
          @errors << "Lambda #{lambda_config.function_name}: #{result[:error]}"
        end
      end
    end

    # Push Kafka configurations
    def push_kafka_configurations
      data_flow.kafka_configurations.each do |kafka_config|
        service = KafkaService.new(kafka_config)

        # Create cluster if not deployed
        unless kafka_config.deployed?
          result = service.create_cluster
          
          if result[:success]
            @results[:kafka] ||= []
            @results[:kafka] << {
              cluster_name: kafka_config.cluster_name,
              cluster_arn: result[:cluster_arn],
              status: 'created'
            }
          else
            @errors << "Kafka #{kafka_config.cluster_name}: #{result[:error]}"
            next
          end
        end

        # Create topics
        topics_result = service.create_topics
        
        if topics_result[:success]
          @results[:kafka] ||= []
          @results[:kafka] << {
            cluster_name: kafka_config.cluster_name,
            topics: kafka_config.topic_names,
            status: 'topics_created'
          }
        else
          @errors << "Kafka topics #{kafka_config.cluster_name}: #{topics_result[:error]}"
        end
      end
    end

    # Pull Kafka configurations
    def pull_kafka_configurations
      data_flow.kafka_configurations.each do |kafka_config|
        next unless kafka_config.deployed?

        service = KafkaService.new(kafka_config)
        result = service.get_cluster_info

        if result[:success]
          info = result[:cluster_info]
          
          kafka_config.update(
            broker_configuration: kafka_config.broker_configuration.merge(
              'kafka_version' => info[:kafka_version],
              'number_of_broker_nodes' => info[:number_of_broker_nodes],
              'zookeeper_connect_string' => info[:zookeeper_connect_string]
            )
          )

          @results[:kafka] ||= []
          @results[:kafka] << {
            cluster_name: kafka_config.cluster_name,
            status: 'synced'
          }
        else
          @errors << "Kafka #{kafka_config.cluster_name}: #{result[:error]}"
        end
      end
    end

    # Push API Gateway configurations
    def push_api_gateway_configurations
      data_flow.api_gateway_configurations.each do |api_config|
        service = ApiGatewayService.new(api_config)
        result = service.create_or_update_api

        if result[:success]
          @results[:api_gateway] ||= []
          @results[:api_gateway] << {
            api_name: api_config.api_name,
            api_id: result[:api_id],
            endpoint_url: result[:endpoint_url],
            status: api_config.deployed? ? 'updated' : 'created'
          }
        else
          @errors << "API Gateway #{api_config.api_name}: #{result[:error]}"
        end
      end
    end

    # Pull API Gateway configurations
    def pull_api_gateway_configurations
      data_flow.api_gateway_configurations.each do |api_config|
        next unless api_config.deployed?

        service = ApiGatewayService.new(api_config)
        
        # Get API info
        api_result = service.get_api_info
        if api_result[:success]
          info = api_result[:api_info]
          
          # Get routes
          routes_result = service.get_routes
          if routes_result[:success]
            api_config.update(
              routes: routes_result[:routes].map { |r|
                {
                  'route_key' => r[:route_key],
                  'route_id' => r[:route_id]
                }
              }
            )
          end

          @results[:api_gateway] ||= []
          @results[:api_gateway] << {
            api_name: api_config.api_name,
            status: 'synced'
          }
        else
          @errors << "API Gateway #{api_config.api_name}: #{api_result[:error]}"
        end
      end
    end

    # Push CloudFormation stack
    def push_cloudformation_stack
      service = CloudFormationService.new(data_flow)
      
      # Check if stack exists
      status_result = service.get_stack_status
      
      result = if status_result[:success]
        service.update_stack
      else
        service.create_stack
      end

      if result[:success]
        @results[:cloudformation] = {
          stack_name: result[:stack_name] || service.send(:stack_name),
          status: status_result[:success] ? 'updated' : 'created'
        }
      else
        @errors << "CloudFormation: #{result[:error]}" unless result[:message]&.include?('No updates')
      end
    end

    # Success result
    def success_result
      {
        success: true,
        message: 'Sync completed successfully',
        details: @results,
        timestamp: Time.current
      }
    end

    # Partial success result
    def partial_success_result
      {
        success: false,
        message: 'Sync completed with errors',
        details: @results,
        errors: @errors,
        timestamp: Time.current
      }
    end

    # Error result
    def error_result(message)
      {
        success: false,
        error: message,
        timestamp: Time.current
      }
    end
  end
end
