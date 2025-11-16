Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  # User profile and signup
  resource :user, only: [ :new, :create, :show, :update, :destroy ] do
    post :link_google
    delete :unlink_google
  end

  # Third-party user creation (guides, etc.)
  post "users/create_guide", to: "users#create_guide", as: :create_guide

  # Admin
  namespace :admin do
    resources :users, only: [ :index ] do
      member do
        patch :update_role
      end
    end
  end

  # OmniAuth callbacks
  get "/auth/:provider/callback", to: "omniauth_callbacks#google_oauth2"
  get "/auth/failure", to: "omniauth_callbacks#failure"

  # Hikes
  resources :hikes do
      member do
          post :refresh_from_openrunner
      end
      collection do
          get :fetch_openrunner_details
      end
  end
  resources :hike_histories
  resources :hike_paths

  # Stats
  get "stats/dashboard", to: "stats#dashboard", as: :stats_dashboard

  # Map test
  get "map_test", to: "map_test#index"
  get "map_test/with_importmap", to: "map_test#with_importmap"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "sessions#new"
end
