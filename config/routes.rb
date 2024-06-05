Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }

  root "prototypes#index"

  resources :users, only: [:show]
  resources :learning_progresses, only: [:index, :create] do
    collection do
      post :check
      get :correct
      get :incorrect 
    end
  end

  resources :prototypes

  # 他のルート
end
