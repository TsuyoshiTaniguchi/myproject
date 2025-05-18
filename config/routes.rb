Rails.application.routes.draw do
  # 認証関連
  devise_for :users, skip: [:passwords], controllers: {
    registrations: "public/registrations",
    sessions: 'public/sessions'
  }
  devise_for :admins, skip: [:registrations, :passwords], controllers: {
    sessions: "admin/sessions"
  }

  # 一般ユーザー関連
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
    resources :users, only: [:index, :destroy]
    resources :posts, only: [:index, :destroy]
    root "dashboard#index"
  end

  # トップページ
  root 'homes#top'
end