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
      Rails.logger.debug "削除対象の Connection: #{connection.inspect}"
      connection.destroy
      redirect_to request.referer, notice: "フォローを解除しました！"
    else
      Rails.logger.debug "削除対象の Connection が見つかりません。"
      redirect_to request.referer, alert: "ユーザー情報が見つかりませんでした。"
    end
  end

  # フォローしているユーザー一覧
  def following
    @user = User.find(params[:id])
    @users = @user.connected_users  # 🔹 `@users` にフォローしているユーザー一覧を代入
  end

  def followers
    @user = User.find(params[:id])
    @users = @user.connected_by_users # 🔹 `@users` にフォローしてくれているユーザー一覧をセット
  end


end