class Admin::UsersController < ApplicationController
  before_action :authenticate_admin!

  def index
    @active_users = User.where(status: "active")
    @inactive_users = User.where(status: "inactive")
  end

  def destroy
    user = User.find(params[:id])
    user.destroy
    redirect_to admin_users_path, notice: "ユーザーを削除しました"
  end
end
