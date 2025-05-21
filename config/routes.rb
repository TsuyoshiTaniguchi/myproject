Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "public/registrations",
    sessions: "public/sessions"
  }

  devise_for :admins,
  path: 'admin',
  controllers: {
    sessions: "admin/sessions",
    passwords: "admin/passwords"
  },
  skip: [:registrations, :sign_out]

  root to: "public/homes#top"
  get '/about' => 'public/homes#about', as: 'about'

  # 一般ユーザー関連
  scope module: :public do
    get '/users/mypage' => 'users#show', as: 'users_mypage'
    get '/users/information/edit' => 'users#edit'
    patch '/users/information' => 'users#update'
    get '/users/unsubscribe' => 'users#unsubscribe'
    patch '/users/withdraw' => 'users#withdraw'

    resources :users, only: [:show, :edit, :update, :destroy] do
      resources :comments, only: [:create, :destroy]
      resources :likes, only: [:create, :destroy]
    end
  end

  # 管理者専用ページ
  namespace :admin do
    

    resources :users, only: [:index, :show, :edit, :update, :destroy, :create]
    resources :posts, only: [:index, :destroy]
    get 'dashboard', to: 'dashboard#index', as: 'dashboard'  # 追加
    root to: "dashboard#index"  # 管理者topページ
    get '/' => 'homes#top'
  end
  
end



