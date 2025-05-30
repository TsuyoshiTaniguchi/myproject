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
    connection = Connection.find_by(followed_id: params[:id], follower_id: current_user.id)
  
    if connection
      connection.destroy!
      @users = current_user.connected_by_users.reload # ✅ データを削除後に最新のリストを取得！
      flash[:notice] = "フォロー解除しました"
      redirect_to followers_user_path(current_user) # ✅ 更新されたデータを反映するためリダイレクト！
    else
      flash[:alert] = "フォロー解除できませんでした"
      redirect_back fallback_location: followers_user_path(current_user)
    end
  end
  

  # フォローしているユーザー一覧
  def following
    @user = User.find(params[:id])
    @users = @user.connected_users  # 🔹 `@users` にフォローしているユーザー一覧を代入
  end

  def followers
    @user = User.find(params[:id])
    @users = User.joins(:connections).where(connections: { followed_id: @user.id }).distinct # ✅ 最新のフォロワーを明示的に取得！
  end
  


end