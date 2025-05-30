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
    user = User.find(params[:id])
    current_user.disconnect(user) # ✅ `disconnect` メソッドを使用！
    
    @users = User.joins(:connections).where(connections: { followed_id: params[:id] }).distinct.reload
  
    respond_to do |format|
      format.html { redirect_back fallback_location: request.referer, notice: "フォロー解除しました" }
      format.js
    end
  end
  

  # フォローしているユーザー一覧
  def following
    @user = User.find(params[:id])
    @users = @user.connected_users  # 🔹 `@users` にフォローしているユーザー一覧を代入
  end

  def followers
    @user = User.find(params[:id])
    @users = User.joins(:connections).where(connections: { followed_id: @user.id }).distinct.reload # ✅ 最新データを強制的に取得！
  end


end