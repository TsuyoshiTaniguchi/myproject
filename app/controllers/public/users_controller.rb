class Public::UsersController < ApplicationController

  before_action :authenticate_user!

  def show
    @user = current_user
    @posts = @user.posts
  end

  def edit
    @user = current_user
  end

  def update
    if current_user.update(user_params)
      redirect_to public_user_path(current_user), notice: "プロフィールを更新しました"
    else
      render :edit
    end
  end
  
  # 退会確認
  def confirm_withdraw
    # ログインしているユーザー本人のデータ
    @user = current_user
  end
  
  def withdraw
    @user = current_user
    @user.destroy
    redirect_to new_user_registration_path, notice: "退会が完了しました"
  end

  private

  def user_params
    params.require(:user).permit(:name, :email)
  end
end