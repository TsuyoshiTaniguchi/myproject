class Admin::ConnectionsController < ApplicationController
  before_action :authenticate_admin!

  def destroy
    connection = Connection.find(params[:id])
    connection.destroy
    redirect_to admin_users_path, notice: "フォロー関係を削除しました！"
  end
  
end