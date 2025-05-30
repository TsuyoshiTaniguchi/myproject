class Admin::ConnectionsController < ApplicationController
  before_action :authenticate_admin!

  def index
    @connections = Connection.includes(:follower, :followed)  # 🔹 全てのフォロー関係を取得
  end
  

  def destroy
    connection = Connection.find(params[:id])
    connection.destroy
    redirect_to admin_connections_path, notice: "フォロー関係を削除しました！"
  end

end