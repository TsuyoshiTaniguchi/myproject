class Public::LikesController < ApplicationController
  before_action :set_post

  def create
    like = current_user.likes.new(post_id: @post.id)
    like.save
    redirect_to posts_path
  end

  def destroy
    like = current_user.likes.find_by(post_id: @post.id)
    like.destroy if like
    redirect_to posts_path
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end
end