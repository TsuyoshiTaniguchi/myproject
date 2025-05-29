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
  skip: [:registrations]

  devise_scope :admin do
    delete 'admin/sign_out', to: 'admin/sessions#destroy'
  end

  devise_scope :user do
    post "users/guest_sign_in", to: "public/sessions#guest_login"
    post "/logout", to: "public/sessions#destroy", as: :logout  # `POST` のルート
    delete "/logout", to: "public/sessions#destroy"  # `DELETE` のルート
  end
  
  root to: "public/homes#top"
  get '/about' => 'public/homes#about', as: 'about'


  # 一般ユーザー関連
  scope module: :public do
    get '/users/mypage' => 'users#mypage', as: 'users_mypage'
  
    resources :posts do
      resources :comments, only: [:create, :destroy] do
        member do
          patch :report  # コメント通報機能
        end
      end
    
      resources :likes, only: [:create, :destroy]  # 「いいね」機能
    
      member do
        patch :report  # 投稿通報機能
      end
    
      collection do
        get :search  # 投稿検索機能
      end
    end
    
   
      

    resources :users, only: [:index, :show, :edit, :update, :destroy] do
      collection do
        get :search  # ユーザー検索機能
      end
      member do
        patch :withdraw
        patch :report  # ユーザー通報機能
      end
      resources :posts, only: [:index, :show, :new, :create, :edit, :update, :destroy]
      resources :groups, only: [:index, :show, :new, :create]  # `create` を追加！
     end
    

    resources :groups, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
      resources :memberships, only: [:create, :destroy]
      resources :posts, only: [:index, :show, :create, :new, :edit, :update, :destroy]
      member do
        post :request_join
        patch :report  # グループ通報機能
        delete :leave  # グループ退会機能
      end
      collection do
        get :search  # グループ検索機能
      end
    end
  end


  # 管理者専用ページ
  namespace :admin do
    resources :users, only: [:index, :show, :edit, :update, :destroy, :create] do
      collection do
        get :search  # 検索機能（管理者用）
      end
      member do
        patch :toggle_status  #  ユーザーのステータス変更機能を追加
      end
    end

    resources :groups, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
      resources :memberships, only: [:create, :destroy]  # 管理者がメンバーを追加・削除
      member do
        delete :remove_group_image
      end
    end

    resources :posts, only: [:index, :show, :edit, :update, :destroy] do
      member do
        patch :report  #  投稿通報機能
        patch :unreport  # 通報解除
      end
      collection do
        get :search  # 検索機能（管理者用）
      end
    end

    resources :comments, only: [:index, :show, :destroy] do
      collection do
        get :search  # 検索機能
      end
      member do
        patch :unreport  #  通報解除を追加
      end
    end

    get 'dashboard', to: 'dashboard#index', as: 'dashboard'  # これを管理者トップページに
    root to: "dashboard#index"  # `root` はここで統一（外に書かない）
  end

end