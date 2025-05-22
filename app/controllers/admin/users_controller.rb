class Admin::UsersController < ApplicationController
  before_action :authenticate_admin!

  def index
    @users_by_status = User.all.group_by(&:status)
    @users = User.where(status: "active")
  end

  def show
    @user = User.find(params[:id])
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    Rails.logger.debug "更新前ステータス: #{@user.status}"
    
    if params[:cancel]
      return redirect_to admin_user_path(@user) 
    end
  
    if @user.update(user_params)
      Rails.logger.debug "更新後ステータス: #{@user.reload.status}"
      redirect_to admin_user_path(@user), notice: "ユーザー情報を更新しました"
    else
      flash[:alert] = @user.errors.full_messages.join(", ")
      render :edit
    end
  end
  

  

  def destroy
    @user = User.find(params[:id])
    @user.destroy
    redirect_to admin_users_path, notice: "ユーザーを削除しました"
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :status, :role)
  end
end