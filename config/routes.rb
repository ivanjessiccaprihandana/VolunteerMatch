Rails.application.routes.draw do
  # Health check for the load balancer / container platform.
  get "up" => "rails/health#show", as: :rails_health_check

  root "pages#home"
  get "/privasi", to: "pages#privacy", as: :privacy
  get "/syarat", to: "pages#terms", as: :terms

  resources :users, only: %i[new create]

  get "/login", to: "sessions#new", as: :login
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout

  # Email confirmation (link from the email) and resending it.
  get "/konfirmasi-email", to: "email_confirmations#show", as: :email_confirmation
  get "/konfirmasi-email/kirim-ulang", to: "email_confirmations#new", as: :new_email_confirmation
  post "/konfirmasi-email/kirim-ulang", to: "email_confirmations#create"

  # Forgotten password.
  resource :password_reset, only: %i[new create edit update], path: "lupa-password"

  get "/dashboard", to: "dashboard#show", as: :dashboard
  resource :profile, only: %i[show edit update]
  resource :account, only: %i[edit destroy]

  resources :volunteer_events do
    resources :event_registrations, only: :create do
      member do
        patch :accept
        patch :reject
        patch :cancel
      end
    end
  end

  namespace :admin do
    root "organizations#index"
    resources :organizations, only: %i[index update]
  end
end
