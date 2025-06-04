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
  end

  
  root to: "public/homes#top"
  get '/about' => 'public/homes#about', as: 'about'

  resources :notifications, only: [:index, :update, :show] do
    member do
      patch :mark_as_read
    end
  end


  # 一般ユーザー関連
  scope module: :public do
    get '/users/mypage' => 'users#mypage', as: 'users_mypage'

    resources :daily_reports, only: [:index, :new, :create, :edit, :update, :destroy]
    
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
        get :search    # 投稿検索機能
      end
    end
  
    resources :connections, only: [:create, :destroy]

    resources :users, only: [:index, :show, :edit, :update, :destroy] do
      collection do
        get :search  # ユーザー検索機能
      end
      get "followed_posts", on: :member
  
      member do
        get :following, to: "connections#following" 
        get :followers, to: "connections#followers" 
        patch :withdraw
        patch :report  # ユーザー通報機能
      end
   
      resources :posts, only: [:index, :show, :new, :create, :edit, :update, :destroy]
      resources :groups, only: [:index, :show, :new, :create] 
     end
    

     resources :groups, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
      resources :memberships, only: [:create, :destroy] do
        member do
          get :owner_dashboard      # オーナー管理ページ
          get :manage_group         # 承認・拒否ページ
          patch :approve_membership # グループ単位で承認
          patch :report_member      # メンバー通報ルートを正しい場所へ移動
          delete :reject_membership # 拒否ルート
        end
      end
    
      resources :posts, only: [:index, :show, :create, :new, :edit, :update, :destroy]
    
      member do
        post :request_join
        patch :report  # グループ通報ルート
        delete :leave  # グループ退会ルート
      end
    
      collection do
        get :search    # グループ検索ルート
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
        patch :unreport       # 通報解除のルート 
        patch :toggle_status  #  ユーザーのステータス変更機能を追加
        get :followers        # フォロワー一覧
        get :following        # ユーザーのフォロー関係は個別ページで管理
      end
    end


    resources :groups, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
      resources :memberships, only: [:create, :destroy] do
        member do
          patch :approve       # メンバー承認処理
          patch :reject        # メンバー拒否処理
          patch :report_member #  メンバー通報ルートを正しい場所へ移動
        end
      end
  
      member do
        patch :unreport #  グループ通報解除
        delete :remove_group_image
        patch :approve  # グループ承認処理（管理者用）
        patch :reject   # グループ拒否処理（管理者用）
      end
    end

  
    resources :posts, only: [:index, :show, :edit, :update, :destroy] do
      member do
        patch :report    #  投稿通報機能
        patch :unreport  # 通報解除
      end
      collection do
        get :search      # 検索機能（管理者用）
      end
    end

    resources :comments, only: [:index, :show, :destroy] do
      collection do
        get :search      # 検索機能
      end
      member do
        patch :unreport  #  通報解除を追加
      end
    end

   
    resources :notifications, only: [:index]

    resources :connections, only: [:destroy]


    get 'dashboard', to: 'dashboard#index', as: 'dashboard'  # これを管理者トップページに
    root to: "dashboard#index"  # `root` はここで統一（外に書かない）
  end

end