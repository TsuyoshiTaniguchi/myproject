class Public::PostsController < ApplicationController
  before_action :authenticate_user!
  before_action :correct_user, only: [:edit, :update, :destroy]

  def index
    @posts = Post.active_users_posts
  end

  def show
    @post = Post.find_by(id: params[:id])
  
    if @post.nil?
      redirect_to posts_path, alert: "指定された投稿は存在しません"
    end
  end

  def new
    @post = Post.new
  end

  def create
    @post = current_user.posts.build(post_params)
    @post.group_id ||= Group.find_or_create_by(name: "Default").id # デフォルトグループを設定
  
    if @post.save
      redirect_to post_path(@post), notice: "投稿が作成されました"
    else
      flash[:alert] = @post.errors.full_messages.join(", ")
      render :new
    end
  end
  
  def update
    @post = current_user.posts.find(params[:id])
  
    if @post.update(post_params)
      redirect_to post_path(@post), notice: "投稿が更新されました"
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
  
    if @post.destroy
      redirect_to request.referer, notice: "投稿が削除されました"
    else
      flash[:alert] = "投稿の削除に失敗しました"
      redirect_to post_path(@post)
    end
  end

  def report
    @post = Post.find_by(id: params[:id])
    if @post&.normal?
      @post.update(status: :reported)
      redirect_to post_path(@post), notice: "投稿を通報しました"
    else
      redirect_to post_path(@post), alert: "この投稿はすでに通報されています"
    end
  end

  def search
    @query = params[:query]
    @posts = Post.where("title LIKE ? OR content LIKE ?", "%#{@query}%", "%#{@query}%")
    render :index
  end

  private

  def post_params
    params.require(:post).permit(:title, :content, :group_id)
  end

  def correct_user
    @post = current_user.posts.find_by(id: params[:id])
    redirect_to public_posts_path, alert: "権限がありません" if @post.nil?
  end
  
end
