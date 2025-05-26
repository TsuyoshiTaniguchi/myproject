class Public::PostsController < ApplicationController
  before_action :authenticate_user!
  before_action :correct_user, only: [:edit, :update, :destroy]

  def index
    @posts = Post.active_users_posts
  end

  def show
    @post = Post.find(params[:id])
    
    #  意図したページから来た場合のみ `session[:return_to]` をセット
    if request.referer.present? && !request.referer.include?("/posts/")
      session[:return_to] = request.referer
    end
  end

  def new
    if params[:group_id].present?
      @group = Group.find_by(id: params[:group_id])
      unless @group
        flash[:alert] = "グループが見つかりません。"
        return redirect_to user_groups_path(current_user)
      end
      @post = @group.posts.new
    else
      @post = current_user.posts.new
    end
  end

  def create
    @group = params[:group_id].present? ? Group.find_by(id: params[:group_id]) : nil
  
    if @group
      @post = @group.posts.build(post_params)
    else
      @post = current_user.posts.build(post_params)
    end
  
    @post.user = current_user
  
    if @post.save
      redirect_to @group ? user_group_post_path(current_user, @group, @post) : post_path(@post), notice: "投稿が作成されました"
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
