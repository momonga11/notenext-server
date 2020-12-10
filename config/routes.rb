Rails.application.routes.draw do
  namespace :v1 do
    resources :projects, only: %i[index show create update destroy] do
      resources :folders, only: %i[index show create update destroy] do
        resources :notes
      end
    end
  end

  scope :v1 do
    mount_devise_token_auth_for 'User', at: 'auth', skip: %i[registrations session password]

    devise_scope :user do
      # session
      post '/auth/sign_in', to: 'devise_token_auth/sessions#create'
      delete '/auth/sign_out', to: 'devise_token_auth/sessions#destroy'

      # password
      put '/auth/password', to: 'devise_token_auth/passwords#update'

      # registrations
      post '/auth/sign_up', to: 'devise_token_auth/registrations#create'
      put '/auth', to: 'devise_token_auth/registrations#update'
      delete '/auth', to: 'devise_token_auth/registrations#destroy'
    end
  end

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
