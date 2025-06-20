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

  get 'maps/show'

  # Maps（共通ルート）
  resources :maps, only: [:show, :edit, :update]

  # 通知（Notifications）
  resources :notifications, only: [:index, :update, :show] do
    member do
      patch :mark_as_read
    end
    collection do
      patch :mark_all_read
    end
  end

  # 一般ユーザー関連
  scope module: :public do
    get '/users/mypage' => 'users#mypage', as: 'users_mypage'


    # 日報 (DailyReports)
    resources :daily_reports, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
      collection do
        get :calendar_data      # /daily_reports/calendar_data(.:format)
        get :performance_data   # /daily_reports/performance_data(.:format)
        get :growth_data
        get :future_growth_data
      end
      resources :tasks, only: %i[create update destroy] do # タスクはあくまで日報詳細の中で CRUD させるだけ
        collection do
          post :bulk_create  # 一括作成用アクション
        end
      end
    end


    resources :posts do
      resources :comments, only: [:create, :destroy] do
        member do
          patch :report  # コメント通報機能
        end
      end
    
      resources :likes, only: [:create, :destroy]  # 「いいね」機能
    
      member do
        patch :report  # 投稿通報機能
        get   :report
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
      member do
        # ConnectionsController に明示的に振り分ける
        post   :follow,   to: 'connections#create'
        delete :unfollow, to: 'connections#destroy'
      end

      # ユーザーに紐づく投稿・グループ（※ グループはネストして使うケースもあるが、重複を避けるため各種
      resources :posts, only: [:index, :show, :new, :create, :edit, :update, :destroy]
     end

     # グループ (Groups) 関連
     resources :groups, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
       # グループ単体の参加申請／脱退
       member do
         post   :request_join     # /groups/:id/request_join
         delete :leave            # /groups/:id/leave
         patch  :report           # /groups/:id/report
         patch  :unreport         # /groups/:id/unreport
       end
       member do
        get  :owner_dashboard    # /groups/:id/owner_dashboard
        get  :manage_group       # /groups/:id/manage_group
       end
       # メンバーシップ承認／拒否／通報／解除
       resources :memberships, only: %i[create destroy] do
         member do
           patch  :approve             # /groups/:group_id/memberships/:id/approve
           delete :reject              # /groups/:group_id/memberships/:id/reject
           patch  :report,   action: :report_member   # /…/report
           patch  :unreport, action: :unreport_member # /…/unreport
         end
       end

       # グループ内投稿一覧や検索などは別にネストしてもOK
       resources :posts, only: %i[index show new create edit update destroy] do
         collection do
           get :search
         end
         member do
           patch :report
           get   :report
         end
       end

       # グループ検索
       collection do
         get :search
       end
     end
   end


  # 管理者専用ページ
  namespace :admin do
    # 管理者トップ（ダッシュボード）
    root to: "dashboard#index"
    get 'dashboard', to: 'dashboard#index'

    # ユーザー管理
    resources :users, only: %i[index show edit update destroy create] do
      collection do
        get :search
      end
      member do
        patch :unreport        # 通報解除
        patch :toggle_status   # ステータス切り替え
        get   :followers
        get   :following
      end
    end
    # 日報管理（詳細＆削除のみ許可）
    resources :daily_reports, only: %i[show destroy]

    # グループ管理
    resources :groups, only: %i[index show new create edit update destroy] do
      member do
        patch  :unreport            # グループ通報解除
        delete :remove_group_image  # 画像削除
      end

      # グループに対するメンバー申請の承認／拒否
      resources :memberships, only: %i[create destroy] do
        member do
          patch  :approve             # 承認
          delete :reject              # 拒否
          patch  :report,   action: :report_member   # メンバー通報
          patch  :unreport, action: :unreport_member # メンバー通報解除
        end
      end
  
    end

    # 投稿管理
    resources :posts, only: %i[index show edit update destroy] do
      collection { get :search }
      member do
        patch :report    # 通報
        patch :unreport  # 通報解除
      end
    end

    # コメント管理
    resources :comments, only: %i[index show destroy] do
      collection { get :search }
      member    { patch :unreport }
    end

    # 通知管理
    resources :notifications, only: %i[index show update] do
      member     { patch :mark_read }
      collection { patch :mark_all_read }
    end

    # フォロー関係の削除だけ
    resources :connections, only: [:destroy]
  end

end