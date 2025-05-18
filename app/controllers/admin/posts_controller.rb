module Admin
  class PostsController < ApplicationController
    before_action :authenticate_admin!

    def index
      @posts = Post.all  # 管理者は全投稿を表示可能
    end

    def destroy
      post = Post.find(params[:id])  # 管理者は全ての投稿を削除可能
      post.destroy
      redirect_to admin_posts_path, notice: "投稿を削除しました"
    end
  end

end