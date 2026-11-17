Rails.application.routes.draw do
  resources :users, only: %i[new create]

  get "/login", to: "sessions#new", as: :login
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout

  get "/dashboard", to: "dashboard#show", as: :dashboard
  resource :profile, only: %i[show edit update]
  resources :volunteer_events

  root "users#new"
end
