Rails.application.routes.draw do
  resources :users, only: %i[new create]

  get "/login", to: "sessions#new", as: :login
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout

  get "/dashboard", to: "dashboard#show", as: :dashboard
  resource :profile, only: %i[show edit update]
  resources :volunteer_events do
    resources :event_registrations, only: :create do
      member do
        patch :accept
        patch :reject
        patch :cancel
      end
    end
  end

  root "users#new"
end
