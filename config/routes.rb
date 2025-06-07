Rails.application.routes.draw do
  # Sidekiq Web UI (for monitoring background jobs)
  require 'sidekiq/web'
  
  # Secure Sidekiq web interface (only allow in development or with authentication)
  if Rails.env.development?
    mount Sidekiq::Web => '/sidekiq'
  else
    # In production, you might want to add authentication
    # Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    #   username == ENV["SIDEKIQ_USERNAME"] && password == ENV["SIDEKIQ_PASSWORD"]
    # end
    mount Sidekiq::Web => '/sidekiq'
  end

  get "music", to: "music#index"
  
  # New multi-step release wizard
  resources :release_wizard, only: [:show, :create] do
    collection do
      get :step1
      post :create_draft
    end
    member do
      get :step2
      get :step3
      post :update_step
    end
  end

  resources :releases do
    resources :tracks, only: [:new, :create, :edit, :update, :destroy]
  end
  get "home/index"
  root to: "home#index"

  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks",
    registrations: "users/registrations"
  }

  resources :artist_profiles, path: 'artists', only: [:show, :edit, :update] do
    member do
      post 'follow', to: 'follows#create'
      delete 'unfollow', to: 'follows#destroy'
    end
  end
  resources :fan_profiles, path: 'fans', only: [:index, :show, :edit, :update]
  
  # Dashboard route for authenticated users
  get 'dashboard', to: 'dashboard#index'

  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
