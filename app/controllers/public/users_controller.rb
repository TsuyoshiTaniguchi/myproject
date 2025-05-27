class Public::UsersController < ApplicationController
  before_action :authenticate_user!

  def mypage
    @user = current_user  # `mypage` はログイン中のユーザー情報を取得する！
    @posts = @user.posts
  end

  def index
    @users = User.where.not(id: current_user.id)
  end

  def show
    @user = User.find(params[:id])  # 他のユーザーのプロフィールを見る
    @posts = @user.posts
  end

  def edit
    @user = current_user
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
    @user = current_user
    @user.withdraw!
    reset_session # セッションをクリア
    redirect_to root_path, notice: "退会しました"
  end

  def search
    @query = params[:query]
    @users = User.where("name LIKE ?", "%#{@query}%")
    render :index
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :profile_image)
  end

end






