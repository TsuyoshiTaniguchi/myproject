class Public::LikesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post

  def create
    like = @post.likes.create!(user: current_user)
    respond_to do |f|
      f.html { redirect_back(fallback_location: posts_path) }
      f.json { render json: { liked: true,  count: @post.likes.count, like_id: like.id } }
    end
  end
  
  def destroy
    like = @post.likes.find_by!(user: current_user)
    like.destroy!
    respond_to do |f|
      f.html { redirect_back(fallback_location: posts_path) }
      f.json { render json: { liked: false, count: @post.likes.count, like_id: nil } }
    end
  end
  

  private
  def set_post
    @post = Post.find(params[:post_id])
  end
end