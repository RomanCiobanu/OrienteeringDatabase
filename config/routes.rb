Rails.application.routes.draw do
  resources :categories
  resources :results
  resources :competitions
  resources :runners
  devise_for :users
  resources :clubs
  root to: 'home#index'
  get 'home/index'
  get 'home/about', as: "about"
  get 'home/compare', as: "compare"
  get 'home/addcompetition', as: "addcompetition"
  get 'home/file', as: "file"
  post 'home/compare', as: "compare_post"
  post 'home/file', as: "file_post"
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
