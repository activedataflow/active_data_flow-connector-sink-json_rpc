# frozen_string_literal: true

ActiveDataFlow::Engine.routes.draw do
  # Routes for ActiveDataFlow management interface
  root to: "dashboard#index"
  
  resources :data_flows, only: [:index, :show] do
    member do
      post :trigger
    end
    
    resources :data_flow_runs, only: [:index, :show, :create]
  end
end
