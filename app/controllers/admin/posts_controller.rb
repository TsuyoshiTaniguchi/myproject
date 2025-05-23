class Admin::PostsController < ApplicationController

  before_action :authenticate_admin!

  def index
    @posts = Post.where(status: :reported)
  end

  def show
    @post = Post.find_by(id: params[:id])
    
    unless @post
      redirect_to admin_posts_path, alert: "指定された投稿は存在しません"
    end
  end

  def unreport
    @post = Post.find_by(id: params[:id])
    if @post&.reported?  # `nil` チェックを追加
      @post.update(status: :normal)
      redirect_to admin_post_path(@post), notice: "通報を解除しました"
    else
      redirect_to admin_posts_path, alert: "投稿が見つかりません"
    end
  end
  

  def edit
    @post = Post.find_by(id: params[:id])
    unless @post
      redirect_to admin_posts_path, alert: "指定された投稿は存在しません"
    end
  end

  def update
    @post = Post.find_by(id: params[:id])
    if @post.update(post_params)
      redirect_to admin_post_path(@post), notice: "投稿を更新しました"
    else
      flash.now[:alert] = @post.errors.full_messages.join(", ")  # エラーメッセージを表示
      render :edit
    end
  end
  

  def destroy
    post = Post.find(params[:id])
    post.destroy
    redirect_to admin_posts_path, notice: "投稿を削除しました"
  end

  def check_admin_role
    redirect_to root_path, alert: "権限がありません" unless current_admin.super_admin?
  end

  private

  def post_params
    params.require(:post).permit(:title, :content, :status, :group_id)
  end

end
