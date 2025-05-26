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
    delete 'users/sign_out', to: 'devise/sessions#destroy'
  end

  root to: "public/homes#top"
  get '/about' => 'public/homes#about', as: 'about'

  # 一般ユーザー関連
  scope module: :public do
    get '/users/mypage' => 'users#mypage', as: 'users_mypage'

      resources :posts do
        resources :comments, only: [:create, :destroy]
        resources :likes, only: [:create, :destroy]
        
        member do
          patch :report
        end
        
        collection do
          get :search
        end
      end
    
      resources :users, only: [:index, :show, :edit, :update, :destroy] do
        resources :posts, only: [:index, :show, :new, :create, :edit, :update, :destroy]
        resources :groups, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
          resources :memberships, only: [:create, :destroy]
          resources :posts, only: [:index, :show, :create, :new, :edit, :update, :destroy]
          post 'request_join', on: :member  
    
          collection do
            get :search
          end
        end
        
        member do
          patch :withdraw
        end
        
        collection do
          get :search
        end
      end
    end
    
    get '/users/information/edit' => 'users#edit'
    patch '/users/information' => 'users#update'
    get '/users/unsubscribe' => 'users#unsubscribe', as: 'users_unsubscribe'
    patch '/users/withdraw' => 'users#withdraw'
    
    namespace :public do
      get 'memberships/create'
      get 'memberships/destroy'
    end

  # 管理者専用ページ
  namespace :admin do
    resources :users, only: [:index, :show, :edit, :update, :destroy, :create] do
      collection do
        get :search  # 検索機能（管理者用）
      end
    end

    resources :groups, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
      resources :memberships, only: [:create, :destroy]  # 管理者がメンバーを追加・削除
    end

    resources :posts, only: [:index, :show, :edit, :update, :destroy] do
      member do
        patch :unreport  # 通報解除
      end
      collection do
        get :search  # 検索機能（管理者用）
      end
    end

    namespace :admin do
      get 'memberships/create'
      get 'memberships/destroy'
    end

    resources :comments, only: [:index, :destroy]

    get 'dashboard', to: 'dashboard#index', as: 'dashboard'  # これを管理者トップページに
    root to: "dashboard#index"  # `root` はここで統一（外に書かない）
  end

end