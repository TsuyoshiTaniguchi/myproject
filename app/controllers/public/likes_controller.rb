class Public::LikesController < ApplicationController
  before_action :authenticate_user!


  def create
    @post = Post.find(params[:post_id])
    @post.likes.create(user_id: current_user.id)
    redirect_to posts_path
  end
  
  def destroy
    @post = Post.find(params[:post_id])
    like = @post.likes.find_by(user_id: current_user.id)
    like.destroy if like
    redirect_to posts_path
  end

end