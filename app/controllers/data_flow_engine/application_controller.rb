module DataFlowEngine
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    before_action :authorize_data_flow_access

    private

    def authorize_data_flow_access
      # Hook for authorization
      # Can be overridden by host application
      if ActiveDataFlow.configuration.authorization_method
        unless send(ActiveDataFlow.configuration.authorization_method)
          render json: { error: 'Unauthorized' }, status: :unauthorized
        end
      end
    end

    def render_error(message, status: :unprocessable_entity)
      render json: { error: message }, status: status
    end

    def render_success(data, status: :ok)
      render json: data, status: status
    end
  end
end
