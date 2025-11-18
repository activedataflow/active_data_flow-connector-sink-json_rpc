# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :active_data_flow do
    namespace :runtime do
      namespace :heartbeat do
        post "/data_flows/heartbeat", to: "data_flows#heartbeat", as: :heartbeat
      end
    end
  end
end
