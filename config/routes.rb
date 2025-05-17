Rails.application.routes.draw do
  devise_for :admins
  devise_for :users
  
  get "users/mypage", to: "users#mypage"
  root 'homes#top'
  resources :posts
  
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
