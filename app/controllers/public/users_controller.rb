class Public::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :restrict_guest_access, only: [:edit, :update, :withdraw]

  def index
    # ログインユーザー、管理者、ゲストユーザーを除外
    @users = User.where.not(id: current_user.id)
                 .where.not(role: "admin")
                 .where.not(email: "guest@example.com")
    # @users が nil にならないように、何も該当しない場合は空のRelationになります
  end

  def mypage
    if current_user.nil?
      redirect_to new_user_session_path, alert: "ログインしてください。"
      return
    end

    @user = current_user
    following_ids = @user.following.pluck(:id)
    # 投稿取得後、明示的に array に変換してフィルタリング
    posts = Post.where(user_id: following_ids)
                .where.not(user_id: @user.id)
                .order(created_at: :desc)
                .limit(10)
                .to_a

    @posts = filter_posts(posts)
    @joined_groups = @user.joined_groups
  end

  def show
    @user = User.find(params[:id])
    @following_users = @user.following

    # 自分の投稿を取得し、配列に変換してフィルタリング
    own_posts = filter_posts(@user.posts.to_a)

    # フォローしているユーザーの投稿を取得してフィルタリング
    followed_user_ids = current_user.following.pluck(:id)
    followed_posts = filter_posts(Post.where(user_id: followed_user_ids).to_a)

    @posts = (own_posts + followed_posts).sort_by(&:created_at).reverse

    # GitHub の情報取得（そのまま）
    @github_repos = Kaminari.paginate_array([]).page(params[:page]).per(6)
    if @user.github_username.present?
      github_repos = GithubService.new(@user.github_username).fetch_repositories || []
      @github_repos = Kaminari.paginate_array(github_repos).page(params[:page]).per(6)
    end
  end

  # ... その他のアクション（index, edit, update, withdraw, etc.）はそのまま ...

  private

  # ここで、投稿がグループ投稿の場合にフィルタする
  # もし投稿の group が存在し、かつそのグループの privacy が "restricted_visibility" で、
  # 現在のユーザーがそのグループのメンバーでない場合、その投稿を除外します。
  def filter_posts(posts)
    posts.reject do |post|
      post.group.present? &&
        post.group.restricted_visibility? &&
        !post.group.users.include?(current_user)
    end
  end

  def user_params
    params.require(:user).permit(:name, :email, :personal_statement, :portfolio_url, :portfolio_file, :profile_image)
  end

  def ensure_guest_user
    @user = User.find(params[:id])
    if @user.guest_user?
      redirect_to user_path(current_user), notice: "ゲストユーザーはプロフィール編集画面へ遷移できません。"
    end
  end

  def restrict_guest_access
    if current_user.guest?
      flash[:alert] = "ゲストユーザーはこの操作を実行できません。"
      redirect_to users_mypage_path
    end
  end
end




