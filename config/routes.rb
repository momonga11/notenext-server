Rails.application.routes.draw do
  namespace :v1 do
    resources :projects, only: %i[index show create update destroy] do
      resources :folders, only: %i[index show create update destroy] do
        resources :notes
      end
    end
  end

  scope :v1 do
    mount_devise_token_auth_for 'User', at: 'auth', skip: %i[registrations password session confirmation], controllers: {
      token_validations: 'v1/auth/token_validations'
    }

    devise_scope :user do
      # session
      post '/auth/sign_in', to: 'devise_token_auth/sessions#create', as: :v1_auth_sign_in
      delete '/auth/sign_out', to: 'devise_token_auth/sessions#destroy', as: :v1_auth_sign_out

      # password
      get '/auth/password', to: 'devise_token_auth/passwords#edit', as: :v1_edit_auth_password
      post '/auth/password', to: 'devise_token_auth/passwords#create', as: :v1_auth_password_create
      put '/auth/password', to: 'devise_token_auth/passwords#update', as: :v1_auth_password_update

      # registrations
      post '/auth/sign_up', to: 'v1/auth/registrations#create', as: :v1_auth_sign_up
      put '/auth', to: 'v1/auth/registrations#update', as: :v1_auth
      delete '/auth', to: 'v1/auth/registrations#destroy', as: :v1_auth_destory

      # confirmation
      get '/auth/confirmation', to: 'devise_token_auth/confirmations#show', as: :v1_auth_confirmation
      post '/auth/confirmation', to: 'devise_token_auth/confirmations#create', as: :v1_auth_confirmation_create

      delete '/auth/avatar', to: 'v1/auth/registrations#purge_avatar', as: :v1_auth_purge_avatar
    end
  end

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
