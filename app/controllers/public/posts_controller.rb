class Public::PostsController < ApplicationController
  before_action :authenticate_user!
  before_action :correct_user, only: [:edit, :update, :destroy]

  def index
    @posts = Post.all
    @posts = Post.active_users_posts
  end

  def show
    @post = Post.find(params[:id])
  end

  def new
    @post = Post.new
  end

  def create
    @post = current_user.posts.build(post_params)
    if @post.save
      redirect_to public_post_path(@post), notice: "投稿が作成されました"
    else
      flash[:alert] = @post.errors.full_messages.join(", ")
      render :new
    end
  end
  
  def update
    @post = current_user.posts.find(params[:id])
    if @post.update(post_params)
      redirect_to public_post_path(@post), notice: "投稿が更新されました"
    else
      flash[:alert] = @post.errors.full_messages.join(", ")
      render :edit
    end
  end


  def edit
    @post = current_user.posts.find(params[:id])
  end

  def destroy
    @post = current_user.posts.find(params[:id])
    @post.destroy
    redirect_to public_posts_path, notice: "投稿が削除されました"
  end

  private

  def post_params
    params.require(:post).permit(:title, :content)
  end

  def correct_user
    @post = current_user.posts.find_by(id: params[:id])
    redirect_to public_posts_path, alert: "権限がありません" if @post.nil?
  end
  
end
