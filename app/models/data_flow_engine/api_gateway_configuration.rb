module DataFlowEngine
  class ApiGatewayConfiguration < ApplicationRecord
    # Associations
    belongs_to :data_flow

    # Validations
    validates :api_name, presence: true
    validates :stage_name, presence: true

    # Callbacks
    before_validation :set_defaults, on: :create

    # Scopes
    scope :deployed, -> { where.not(api_id: nil) }

    # Instance methods
    def deploy_api
      service = DataFlowEngine::ApiGatewayService.new(self)
      result = service.create_or_update_api
      
      if result[:success]
        update(
          api_id: result[:api_id],
          endpoint_url: result[:endpoint_url]
        )
      end
      
      result
    end

    def update_routes(new_routes)
      update(routes: new_routes)
      
      if deployed?
        service = DataFlowEngine::ApiGatewayService.new(self)
        service.update_routes
      end
    end

    def deployed?
      api_id.present?
    end

    def route_list
      routes.is_a?(Array) ? routes : []
    end

    def add_route(route_config)
      current_routes = route_list
      current_routes << route_config
      update(routes: current_routes)
      
      update_routes(current_routes) if deployed?
    end

    def remove_route(route_key)
      current_routes = route_list
      current_routes.reject! { |r| r['route_key'] == route_key }
      update(routes: current_routes)
      
      update_routes(current_routes) if deployed?
    end

    def full_endpoint_url(path = '')
      return nil unless endpoint_url.present?
      "#{endpoint_url}#{path}"
    end

    private

    def set_defaults
      self.stage_name ||= 'production'
      self.routes ||= []
    end
  end
end
