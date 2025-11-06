require 'aws-sdk-apigatewayv2'

module DataFlowEngine
  class ApiGatewayService
    attr_reader :api_gateway_configuration

    def initialize(api_gateway_configuration)
      @api_gateway_configuration = api_gateway_configuration
      @client = Aws::ApiGatewayV2::Client.new
    end

    # Create or update API
    def create_or_update_api
      if api_gateway_configuration.deployed?
        update_api
      else
        create_api
      end
    rescue Aws::ApiGatewayV2::Errors::ServiceError => e
      { success: false, error: e.message }
    end

    # Create new API Gateway
    def create_api
      response = @client.create_api({
        name: api_gateway_configuration.api_name,
        protocol_type: 'HTTP',
        description: "DataFlow API: #{api_gateway_configuration.data_flow.name}",
        tags: {
          'ManagedBy' => 'ActiveDataFlow',
          'DataFlow' => api_gateway_configuration.data_flow.name
        }
      })

      api_id = response.api_id

      # Create routes
      create_routes(api_id)

      # Create stage and deployment
      stage_result = create_stage(api_id)

      {
        success: true,
        api_id: api_id,
        api_endpoint: response.api_endpoint,
        endpoint_url: "#{response.api_endpoint}/#{api_gateway_configuration.stage_name}"
      }
    rescue Aws::ApiGatewayV2::Errors::ServiceError => e
      { success: false, error: e.message }
    end

    # Update existing API
    def update_api
      response = @client.update_api({
        api_id: api_gateway_configuration.api_id,
        name: api_gateway_configuration.api_name,
        description: "DataFlow API: #{api_gateway_configuration.data_flow.name}"
      })

      # Update routes
      update_routes

      {
        success: true,
        api_id: response.api_id,
        api_endpoint: response.api_endpoint
      }
    rescue Aws::ApiGatewayV2::Errors::ServiceError => e
      { success: false, error: e.message }
    end

    # Create routes for the API
    def create_routes(api_id = nil)
      target_api_id = api_id || api_gateway_configuration.api_id
      return { success: false, error: 'API ID not found' } unless target_api_id

      created_routes = []

      api_gateway_configuration.route_list.each do |route_config|
        response = @client.create_route({
          api_id: target_api_id,
          route_key: route_config['route_key'],
          target: route_config['integration_uri'] ? "integrations/#{create_integration(target_api_id, route_config)}" : nil
        })

        created_routes << {
          route_id: response.route_id,
          route_key: response.route_key
        }
      end

      {
        success: true,
        routes: created_routes
      }
    rescue Aws::ApiGatewayV2::Errors::ServiceError => e
      { success: false, error: e.message }
    end

    # Update routes
    def update_routes
      return { success: false, error: 'API not deployed' } unless api_gateway_configuration.deployed?

      # Get existing routes
      existing_routes = @client.get_routes({
        api_id: api_gateway_configuration.api_id
      }).items

      # Delete existing routes (except $default)
      existing_routes.each do |route|
        next if route.route_key == '$default'
        
        @client.delete_route({
          api_id: api_gateway_configuration.api_id,
          route_id: route.route_id
        })
      end

      # Create new routes
      create_routes
    rescue Aws::ApiGatewayV2::Errors::ServiceError => e
      { success: false, error: e.message }
    end

    # Create integration for a route
    def create_integration(api_id, route_config)
      response = @client.create_integration({
        api_id: api_id,
        integration_type: route_config['integration_type'] || 'AWS_PROXY',
        integration_uri: resolve_integration_uri(route_config['integration_uri']),
        payload_format_version: '2.0'
      })

      response.integration_id
    end

    # Create stage
    def create_stage(api_id)
      response = @client.create_stage({
        api_id: api_id,
        stage_name: api_gateway_configuration.stage_name,
        auto_deploy: true,
        description: "Stage for #{api_gateway_configuration.data_flow.name}"
      })

      {
        success: true,
        stage_name: response.stage_name
      }
    rescue Aws::ApiGatewayV2::Errors::ServiceError => e
      { success: false, error: e.message }
    end

    # Get API details
    def get_api_info
      return { success: false, error: 'API not deployed' } unless api_gateway_configuration.deployed?

      response = @client.get_api({
        api_id: api_gateway_configuration.api_id
      })

      {
        success: true,
        api_info: {
          api_id: response.api_id,
          name: response.name,
          protocol_type: response.protocol_type,
          api_endpoint: response.api_endpoint,
          created_date: response.created_date
        }
      }
    rescue Aws::ApiGatewayV2::Errors::ServiceError => e
      { success: false, error: e.message }
    end

    # Get routes
    def get_routes
      return { success: false, error: 'API not deployed' } unless api_gateway_configuration.deployed?

      response = @client.get_routes({
        api_id: api_gateway_configuration.api_id
      })

      {
        success: true,
        routes: response.items.map { |route|
          {
            route_id: route.route_id,
            route_key: route.route_key,
            target: route.target
          }
        }
      }
    rescue Aws::ApiGatewayV2::Errors::ServiceError => e
      { success: false, error: e.message }
    end

    # Delete API
    def delete_api
      return { success: false, error: 'API not deployed' } unless api_gateway_configuration.deployed?

      @client.delete_api({
        api_id: api_gateway_configuration.api_id
      })

      { success: true }
    rescue Aws::ApiGatewayV2::Errors::ServiceError => e
      { success: false, error: e.message }
    end

    private

    # Resolve integration URI (e.g., replace placeholder with actual Lambda ARN)
    def resolve_integration_uri(uri)
      if uri == 'lambda_function_arn'
        # Get Lambda ARN from associated Lambda configuration
        lambda_config = api_gateway_configuration.data_flow.lambda_configurations.first
        return lambda_config&.aws_function_arn if lambda_config&.deployed?
      end
      
      uri
    end
  end
end
