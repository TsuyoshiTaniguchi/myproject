class Public::LikesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post

  def create
    @like = @post.likes.create(user: current_user)
    redirect_to request.referrer || posts_path, notice: "いいねしました！"
  end
  
  def destroy
    @post = Post.find(params[:post_id])
    @like = @post.likes.find_by(user_id: current_user.id)
  
    @like.destroy if @like.present?
  
    redirect_to request.referrer || posts_path, notice: "いいねを解除しました！"
  end



  private

  def set_post
    @post = Post.find(params[:post_id])
  end


end