Rails.application.routes.draw do
  get "programs/show"
  get "programs/new"
  get "profiles/show"
  get "meets/show"
  get "matches/new"
  get "courts/show"
  devise_for :users
  root to: "maps#index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  resources :courts, only: [ :show ]
  resources :matches, only: [ :new, :create ]
  resources :meets, only: [ :show, :destroy ] do
    member do
      post "join"
    end
  end
  resources :profiles, only: [ :show, :update ]
  resources :programs, only: [ :show, :new, :create ] do
    resources :meets, only: [ :new, :create ]
  end
end
