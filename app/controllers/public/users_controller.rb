class Public::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :restrict_guest_access, only: [:edit, :update, :withdraw] 
  
  def mypage
    @user = current_user  # `mypage` はログイン中のユーザー情報を取得する
    @posts = @user.posts
  end

  def index
    @users = User.where.not(id: current_user.id)
    @users = User.where.not(role: ["admin"]).where.not(email: "guest@example.com")
  end


  def show
    @user = User.find(params[:id])  # 他のユーザーのプロフィールを見る
    @connected_users = @user.connected_users
    @connected_by_users = @user.connected_by_users
  
    # 自分の投稿を取得
    own_posts = @user.posts
  
    # フォローしているユーザーの投稿を取得
    followed_user_ids = current_user.connected_users.pluck(:id)
    followed_posts = Post.where(user_id: followed_user_ids)
  
    # 自分の投稿 + フォローユーザーの投稿を統合し、最新順に並び替え
    @posts = (own_posts + followed_posts).sort_by(&:created_at).reverse
  end

  def edit
    if current_user.guest?
      redirect_to users_mypage_path, alert: "ゲストユーザーはプロフィールを編集できません。"
    else
      @user = current_user
    end
  end

  def update
    @user = current_user
    if @user.update(user_params)
      redirect_to users_mypage_path, notice: "プロフィールを更新しました"
    else
      render :edit
    end
  end


  def unsubscribe
  end
  
  # 退会確認
  def confirm_withdraw
    # ログインしているユーザー本人のデータ
    @user = current_user
  end


  def withdraw
    if current_user.guest?
      redirect_to users_mypage_path, alert: "ゲストユーザーは退会できません。"
    else
      current_user.withdraw!
      reset_session
      redirect_to root_path, notice: "退会しました"
    end
  end

  def followed_posts
    user = User.find(params[:id]) # 指定されたユーザーを取得
    @posts = Post.where(user_id: user.connected_users.pluck(:id)) # フォローしているユーザーの投稿を取得
  end

  def search
    @query = params[:query]
    @users = User.where("name LIKE ?", "%#{@query}%")
    render :index
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :personal_statement, :portfolio_url, :portfolio_file, :profile_image)
  end

  def ensure_guest_user
    @user = User.find(params[:id])
    if @user.guest_user?
      redirect_to user_path(current_user) , notice: "ゲストユーザーはプロフィール編集画面へ遷移できません。"
    end
  end  

  def restrict_guest_access
    if current_user.guest?
      flash[:alert] = "ゲストユーザーはこの操作を実行できません。"
      redirect_to users_mypage_path  #  `users_mypage_path` にリダイレクト
    end
  end


end






