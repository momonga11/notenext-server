Rails.application.routes.draw do
  namespace :v1 do
    resources :projects, only: %i[index show create update destroy] do
      get 'notes', to: 'notes#all'
      put 'notes/:id/images/attach', to: 'notes#attach_image', as: :note_image_attach
      resources :notes, only: :show
      resources :folders, only: %i[index show create update destroy] do
        resources :notes
      end
    end
    get 'users/sample', to: 'users#show_sample'
  end

  scope :v1 do
    mount_devise_token_auth_for 'User', at: 'auth', skip: %i[registrations password session confirmation], controllers: {
      token_validations: 'v1/auth/token_validations'
    }

    devise_scope :user do
      # session
      post '/auth/sign_in', to: 'v1/auth/sessions#create', as: :v1_auth_sign_in
      delete '/auth/sign_out', to: 'v1/auth/sessions#destroy', as: :v1_auth_sign_out
      post '/auth/sign_in_sample', to: 'v1/auth/sessions#create_sample', as: :v1_auth_sign_in_sample

      # password
      get '/auth/password', to: 'v1/auth/passwords#edit', as: :v1_edit_auth_password
      post '/auth/password', to: 'v1/auth/passwords#create', as: :v1_auth_password_create
      put '/auth/password', to: 'v1/auth/passwords#update', as: :v1_auth_password_update

      # registrations
      post '/auth/sign_up', to: 'v1/auth/registrations#create', as: :v1_auth_sign_up
      put '/auth', to: 'v1/auth/registrations#update', as: :v1_auth
      delete '/auth', to: 'v1/auth/registrations#destroy', as: :v1_auth_destory
      delete '/auth/avatar', to: 'v1/auth/registrations#destroy_avatar', as: :v1_auth_avatar

      # confirmation
      get '/auth/confirmation', to: 'v1/auth/confirmations#show', as: :v1_auth_confirmation
      post '/auth/confirmation', to: 'v1/auth/confirmations#create', as: :v1_auth_confirmation_create
    end
  end
end
