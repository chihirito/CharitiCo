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
      get :choose_language 
    end
  end

  resources :prototypes

  # choose_languageアクションのルートを追加
  get 'choose_language', to: 'learning_progresses#choose_language', as: 'choose_language'
end
