Rails.application.routes.draw do
  namespace :v1 do
    resources :users
    resources :projects, only: %i[show create show update destroy] do
      resources :folders, only: %i[index show create update destroy] do
        resources :notes
      end
    end
  end

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
