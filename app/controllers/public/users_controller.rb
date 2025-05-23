class Public::UsersController < ApplicationController
  before_action :authenticate_user!

  def mypage
    @user = current_user  # `mypage` はログイン中のユーザー情報を取得する！
    @posts = @user.posts
  end

  def index
    @users = User.all
  end

  def show
    @user = User.find(params[:id])  # 他のユーザーのプロフィールを見る
    @posts = @user.posts
  end

  def edit
    @user = User.find(current_user.id)
    @user = current_user
  end

  def update
    @user = User.find(current_user.id)
    if @user.update(user_params)
      redirect_to users_mypage_path
    else 
      @user = User.find(current_user.id)
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
    @user = User.find(params[:id])
    @user.withdraw!
    reset_session # ここでセッションリセット
    redirect_to root_path, notice: "退会しました"
  end

  def search
    @query = params[:query]
    @users = User.where("name LIKE ?", "%#{@query}%")
    render :index
  end

  private

  def user_params
    params.require(:user).permit(:name, :email)
  end

end






