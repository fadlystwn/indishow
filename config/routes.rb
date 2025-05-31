Rails.application.routes.draw do
  resources :releases do
    resources :tracks, only: [:new, :create, :edit, :update, :destroy]
  end
  get "home/index"
  root to: "home#index"

  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks",
    registrations: "users/registrations"
  }

  resources :artist_profiles, path: 'artists', only: [:show, :edit, :update]

  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
