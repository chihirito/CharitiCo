Rails.application.routes.draw do
  devise_for :users

  root "prototypes#index"

  resources :users, only: [:show]
  resources :learning_progresses do
    collection do
      post :check
      get :correct
      get :incorrect 
      post :increment_coins
      get :next_question
      get :spanish_next_question 
      get :choose_language 
    end
  end

  resources :prototypes

  # choose_languageアクションのルートを追加
  get 'choose_language', to: 'learning_progresses#choose_language', as: 'choose_language'

  get 'spanish_learning', to: 'learning_progresses#spanish_learning', as: 'spanish_learning'
end

