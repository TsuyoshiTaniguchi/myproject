class Public::LikesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post

  def create
    @like = @post.likes.create(user: current_user)

    respond_to do |format|
      format.js { render 'public/likes/create' } # 修正！
    end
  end


  def destroy
    @like = @post.likes.find_by(user: current_user)
    @like.destroy

    respond_to do |format|
      format.js { render 'public/likes/destroy' } # 修正！
    end
  end



  private

  def set_post
    @post = Post.find(params[:post_id])
  end


end