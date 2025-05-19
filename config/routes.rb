Rails.application.routes.draw do
  # 認証関連
  devise_for :users, controllers: {
    registrations: "public/registrations",
    sessions: "public/sessions"
  }, path: "users"

  devise_for :admins, controllers: {
    sessions: "admin/sessions"
  }, path: "admin"

  

  # 一般ユーザー関連
  scope module: :public do
    get '/users/mypage' => 'users#show'
    get '/users/information/edit' => 'users#edit'
    patch '/users/information' => 'users#update'
    patch '/users/withdraw' => 'users#withdraw'
  end
  namespace :public do
    resources :users, only: [:show, :edit, :update, :destroy] do
      member do
        patch :withdraw
      end
    end

    resources :posts do
      resources :comments, only: [:create, :destroy]
      resources :likes, only: [:create, :destroy]
    end
  end

  # 管理者専用ページ
  namespace :admin do
    resources :users, only: [:index, :show, :edit, :update, :destroy, :create]
    resources :posts, only: [:index, :destroy]
    root to: "dashboard#index" # 例: 管理者トップページ用コントローラ
  end


  # トップページ
  root 'homes#top'
  get 'about', to: 'homes#about' 

end

