Rails.application.routes.draw do
  resources :groups
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
  post 'home/compare', as: "compare_post"
  get 'home/merge', as: "merge"
  post 'home/merge', as: "merge_post"
  get 'home/addcompetition', as: "addcompetition"
  get 'home/add_competition_file', as: "competition_file"
  post 'home/add_competition_file', as: "competition_file_post"
  get 'home/count_rang', as: "rang"
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
