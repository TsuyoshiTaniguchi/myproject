class Admin::HomesController < ApplicationController
  before_action :authenticate_admin!

  def dashboard
    @posts = Post.order(created_at: :desc).limit(10) # 最新の投稿を取得
    @users = User.order(created_at: :desc).limit(10) # 最新のユーザーを取得
    @admin_logs = AdminLog.order(created_at: :desc).limit(10) if defined?(AdminLog) # 管理アクション履歴
  end
end