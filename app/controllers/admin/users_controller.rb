class Admin::UsersController < ApplicationController
  before_action :authenticate_admin!

  def index
    @users = User.group_by(&:status) # ユーザーをステータスごとに分類
  end

  def show
    @user = User.find(params[:id])
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    user = User.find(params[:id])
    if user.update(user_params)
      redirect_to admin_user_path(user), notice: "ユーザー情報を更新しました"
    else
      render :edit, alert: "更新に失敗しました"
    end
  end

  def destroy
    user = User.find(params[:id])
    if user.destroy
      redirect_to admin_users_path, notice: "ユーザーを削除しました"
    else
      redirect_to admin_users_path, alert: "ユーザー削除に失敗しました"
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :status, :role)
  end
  
end