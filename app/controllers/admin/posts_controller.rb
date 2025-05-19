module Admin
  class PostsController < ApplicationController
    before_action :authenticate_admin!

    def index
      @posts = Post.all
    end

    def destroy
      post = Post.find(params[:id])
      post.destroy
      redirect_to admin_posts_path, notice: "投稿を削除しました"
    end
  end
end