Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }

  root "prototypes#index"

  resources :users, only: [:show]
  resources :learning_progresses do
    collection do
      post :check
      get :correct
      get :incorrect 
      post :increment_coins
      get :next_question
    end
  end

  resources :prototypes

  # 他のルート
end
