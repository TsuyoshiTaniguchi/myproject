class Admin::DashboardController < Admin::ApplicationController
  before_action :authenticate_admin!

  def index
    @recent_posts = Post.order(created_at: :desc).limit(5)
    @recent_users = User.order(created_at: :desc).limit(5)
    @recent_comments = ::Comment.order(created_at: :desc).limit(5)
  end
end