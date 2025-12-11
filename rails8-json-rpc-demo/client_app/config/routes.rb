Rails.application.routes.draw do
  # Mount ActiveDataFlow engine for DataFlow management
  mount ActiveDataFlow::Engine => "/active_data_flow"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Application routes
  root "dashboard#index"
  resources :users
  resources :orders
  resources :outgoing_records, only: [:index, :show] do
    member do
      patch :retry
    end
  end
  
  # Data creation routes
  namespace :data do
    get :new
    post :create_user
    post :create_order
  end
end
