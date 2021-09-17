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
  post 'home/compare', as: "compare_post"
  get 'home/addcompetition', as: "addcompetition"
  get 'home/add_competition_file', as: "competition_file"
  post 'home/add_competition_file', as: "competition_file_post"
  get 'home/add_runners_file', as: "runner_file"
  post 'home/add_runners_file', as: "runner_file_post"
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
