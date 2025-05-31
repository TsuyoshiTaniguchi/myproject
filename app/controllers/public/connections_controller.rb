class Public::ConnectionsController < ApplicationController
  before_action :authenticate_user!

  # ユーザーフォロー
  def create
    user = User.find(params[:user_id])
    current_user.connect(user)
    redirect_to request.referer, notice: "#{user.name}さんをフォローしました！"
  end
  
  # フォロー解除
  def destroy
    connection = Connection.find_by(id: params[:id])
  
    if connection
      connection.destroy!
      @users = User.joins(:connections).where(connections: { followed_id: connection.followed_id }).distinct.reload
  
      respond_to do |format|
        format.html { redirect_back fallback_location: request.referer, notice: "フォロー解除しました" }
        format.js
      end
    else
      flash[:alert] = "フォロー解除できませんでした"
      redirect_back fallback_location: request.referer
    end
  end
  

  # フォローしているユーザー一覧
  def following
    @user = User.find(params[:id])
    @users = @user.following  # `@users` にフォローしているユーザー一覧を代入
  end

  def followers
    @user = User.find(params[:id])
    @users = @user.followers 
  end


end