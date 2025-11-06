DataFlowEngine::Engine.routes.draw do
  resources :data_flows, only: [:index, :show, :create, :update, :destroy] do
    member do
      post :sync
      post :push
      post :pull
      get :status
    end
  end

  # Dynamic routes for custom DataFlow objects
  # These are generated at runtime based on loaded DataFlow classes
  root to: "data_flows#index"
end
