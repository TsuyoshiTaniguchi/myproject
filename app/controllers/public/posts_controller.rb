class Public::PostsController < ApplicationController
  before_action :authenticate_user!
  before_action :correct_user, only: [:edit, :update, :destroy]
  before_action :restrict_guest_access, only: [:new, :create, :report]

  def index
    @posts = Post.active_users_posts.with_attached_images.includes(:user).where(users: { status: 0 })
  end


  def show
    @post = Post.find_by(id: params[:id]) # `find_by` を使用し、削除済みの投稿に対応
  
    if @post.nil?
      flash[:alert] = "投稿が見つかりませんでした。"
      redirect_to group_posts_path(params[:group_id]) #  削除済みなら投稿一覧へリダイレクト
      return
    end
  
    # 意図したページから来た場合のみ `session[:return_to]` をセット
    if request.referer.present? && !request.referer.include?("/posts/")
      session[:return_to] = request.referer
    end
  end

  def new
    if current_user.guest?
      flash[:alert] = "ゲストユーザーは投稿できません。"
      return redirect_to posts_path
    end
    
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
    # `group_id` がリクエストに含まれている場合、そのグループを取得。なければ `nil`
    @group = params[:group_id].present? ? Group.find_by(id: params[:group_id]) : nil
  
    # `@group` が存在する場合、そのグループに紐づく投稿を作成。なければ、個人投稿として作成
    @post = @group ? @group.posts.build(post_params) : current_user.posts.build(post_params)
    
    # 投稿したユーザーを設定（明示的に `current_user` をセット）
    @post.user = current_user
  
    # 投稿を保存し、成功した場合はリダイレクト
    if @post.save
      session[:return_to] = @group ? group_posts_path(@group) : posts_path # 新規投稿後は投稿一覧へ戻れるようセット
      redirect_to @group ? group_post_path(@group, @post) : post_path(@post), notice: "投稿が作成されました" 
    else
      # エラーが発生した場合、エラーメッセージを `flash[:alert]` に保存し、新規投稿フォームを再表示
      flash[:alert] = @post.errors.full_messages.join(", ")
      render :new
    end
  end
  
  def update
    @post = current_user.posts.find(params[:id])
  
    # 画像を削除する処理
    if params[:remove_image].present?
      params[:remove_image].each do |image_id|
        image = @post.images.find(image_id)
        image.purge # 画像を削除
      end
    end
  
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
    @post = current_user.posts.find_by(id: params[:id]) #  `find_by` を使い、エラーを防ぐ
  
    if @post
      @group = @post.group # 投稿が属するグループを取得
      @post.destroy
  
      # 削除後は投稿一覧ページへリダイレクト
      redirect_to @group ? group_posts_path(@group) : posts_path, notice: "投稿が削除されました！"
    else
      flash[:alert] = "投稿が見つかりませんでした！"
      redirect_to posts_path
    end
  end

  def report
    @post = Post.find(params[:id])
  
    if @post.update(reported: true)
      # 通報時に管理者へ通知 (`user_id` を使用)
      Notification.create!(
        recipient_id: Admin.first.id, # 管理者宛の通知
        user_id: current_user.id, # `sender_id` の代わりに `user_id` を使用！
        notification_type: "post_report",
        source_id: @post.id,
        source_type: "Post",
        read: false
      )
  
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
    params.require(:post).permit(:title, :content, :group_id, images: [])
  end

  def correct_user
    @post = current_user.posts.find_by(id: params[:id])
    redirect_to public_posts_path, alert: "権限がありません" if @post.nil?
  end

  def restrict_guest_access
    if current_user.guest?
      flash[:alert] = "ゲストユーザーはこの操作を実行できません。"
      redirect_back(fallback_location: posts_path)
    end
  end
  
end
