class Public::PostsController < ApplicationController
  before_action :authenticate_user!
  before_action :correct_user, only: [:edit, :update, :destroy]
  before_action :restrict_guest_access, only: [:new, :create, :report]

  def index
    @query    = params[:query]
    @filter   = params[:filter]
    @category = params[:category]
    @tag      = params[:tag]

    # 初めに投稿全体のスコープを定義
    posts_scope = Post.visible_to(current_user).order(created_at: :desc)

    # フォローしている人の投稿のみ
    if @filter == "following"
      following_ids = current_user.following.pluck(:id)
      posts_scope = posts_scope.where(user_id: following_ids)
    end

    # カテゴリフィルター（"すべて" 以外の場合のみ）
    if @category.present? && @category != "すべて"
      posts_scope = posts_scope.where(category: @category)
    end

    # キーワード検索
    if @query.present?
      posts_scope = posts_scope.where("title LIKE ? OR content LIKE ?", "%#{@query}%", "%#{@query}%")
    end

    # タグ検索（ActsAsTaggableOn の tagged_with を使用）
    if @tag.present?
      posts_scope = posts_scope.tagged_with(@tag)
    end

    @posts = posts_scope.page(params[:page]).per(6)
  end

  def show
    @post = Post.find_by(id: params[:id]) # 存在しない投稿（削除済み等）に対応

    if @post.nil?
      flash[:alert] = "投稿が見つかりませんでした。"
      redirect_to group_posts_path(params[:group_id])
      return
    end

    @post.reload

    # 意図したページから来た場合のみ、リダイレクト先をセッションにセット
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
    @group = params[:group_id].present? ? Group.find_by(id: params[:group_id]) : nil
    @post  = @group ? @group.posts.build(post_params) : current_user.posts.build(post_params)
    @post.user = current_user

    if @post.save
      session[:return_to] = @group ? group_posts_path(@group) : posts_path
      redirect_to (@group ? group_post_path(@group, @post) : post_path(@post)), notice: "投稿が作成されました"
    else
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
        image.purge
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
    @post = current_user.posts.find_by(id: params[:id])
    if @post
      @group = @post.group
      @post.destroy
      redirect_to (@group ? group_posts_path(@group) : posts_path), notice: "投稿が削除されました！"
    else
      flash[:alert] = "投稿が見つかりませんでした！"
      redirect_to posts_path
    end
  end

  def report
    @post = Post.find(params[:id])
    return redirect_to @post, alert: 'ゲストユーザーは通報できません' if current_user.guest?
    return redirect_to @post, alert: 'この投稿はすでに通報されています' if @post.reported?
  
    # ここを update_column から reported! に  
    @post.reported!    # status: :reported (1) をセットする enum メソッド
  
    # 通知まわりはそのまま
    admin = User.find_or_create_by!(email: 'admin_notifier@example.com') do |u|
      u.password = SecureRandom.urlsafe_base64
      u.name     = 'System Admin'
    end
    Notification.create!(user: admin, source: @post, notification_type: :post_report)
  
    redirect_to @post, notice: '投稿を通報しました'
  end
  

  def search
    @query = params[:query]
    @posts = Post.visible_to(current_user)
                 .where("title LIKE ? OR content LIKE ?", "%#{@query}%", "%#{@query}%")
                 .page(params[:page]).per(6)
    render :index
  end

  private

  def post_params
    params.require(:post).permit(:title, :content, :group_id, :category, :tag_list, images: [])
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
