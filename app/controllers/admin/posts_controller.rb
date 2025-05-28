class Admin::PostsController < ApplicationController

  before_action :authenticate_admin!

  def index
    if params[:reported_only] == "true"
      @posts = Post.where(status: "reported").order(updated_at: :desc).distinct  # ✅ 通報済み投稿のみ
    else
      @posts = Post.where(status: ["reported", "normal"]).order(updated_at: :desc).distinct  # ✅ **通報済み & 正常な投稿を両方表示**
    end
  end

  def show
    @post = Post.find_by(id: params[:id])
    
    unless @post
      redirect_to admin_posts_path, alert: "指定された投稿は存在しません"
    else
      @post.reload  # ✅ 最新データを取得！
    end
  end

  def report
    @post = Post.find_by(id: params[:id])
    if @post
      @post.update(reported: true)  # ✅ `reported` を `true` に更新
      redirect_to admin_post_path(@post), notice: "投稿を通報しました"
    else
      redirect_to admin_posts_path, alert: "投稿が見つかりません"
    end
  end

  def unreport
    @post = Post.find_by(id: params[:id])
    Rails.logger.info "Unreport action triggered for Post ID: #{@post&.id}"  # ✅ ログを追加
  
    if @post&.reported?
      if @post.update(status: :normal)  # ✅ `status` を `normal` に変更
        redirect_to admin_post_path(@post), notice: "通報を解除しました"
      else
        Rails.logger.error("Failed to update reported: #{@post.errors.full_messages.join(", ")}")  # ✅ エラーをログに記録
        redirect_to admin_posts_path, alert: "通報解除に失敗しました"
      end
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

  def search
    @query = params[:query]
    @posts = Post.where("title LIKE ? OR content LIKE ?", "%#{@query}%", "%#{@query}%")
    render :index
  end

  private

  def post_params
    params.require(:post).permit(:title, :content, :status, :group_id)
  end

end
