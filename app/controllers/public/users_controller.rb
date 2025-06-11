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
    @daily_reports = DailyReport.where(user_id: current_user.id)

    # 投稿取得後、明示的に array に変換してフィルタリング
    posts = Post.where(user_id: following_ids)
                .where.not(user_id: @user.id)
                .order(created_at: :desc)
                .limit(10)
                .to_a

    @posts = filter_posts(posts)
    @joined_groups = @user.joined_groups
  end

  def edit
    if current_user.guest?
      redirect_to users_mypage_path, alert: "ゲストユーザーはプロフィール編集できません。"
    else
      @user = current_user
    end
  end

  def update
    @user = current_user  # もしくは適切なユーザーの取得方法
    if @user.update(user_params)
      redirect_to user_path(@user), notice: "プロフィールが更新されました。"
    else
      render :edit, alert: "更新に失敗しました。"
    end
  end

  def show
    @user = User.find(params[:id])
    @following_users = @user.following
  
    # 投稿のフィルタリング
    own_posts = filter_posts(@user.posts.to_a)
    followed_user_ids = current_user.following.pluck(:id)
    followed_posts = filter_posts(Post.where(user_id: followed_user_ids).to_a)
    @posts = (own_posts + followed_posts).sort_by(&:created_at).reverse
  
    if @user.daily_reports_public?
      @daily_reports = @user.daily_reports.public_report.order(date: :desc)
    else
      @daily_reports = [] # もしくは別メッセージを表示
      flash.now[:alert] = "このユーザーは日報を公開していません。"
    end
  end

  # 退会確認
  def confirm_withdraw
    # ログインしているユーザー本人のデータ
    @user = current_user
  end

  def withdraw
    if current_user.guest?
      redirect_to users_mypage_path, alert: "ゲストユーザーは退会できません。"
    else
      current_user.withdraw!
      reset_session
      redirect_to root_path, notice: "退会しました"
    end
  end

  def followed_posts
    user = User.find(params[:id]) # 指定されたユーザーを取得
    @posts = Post.where(user_id: user.connected_users.pluck(:id)) # フォローしているユーザーの投稿を取得
  end

  def search
    @query = params[:query]
    @users = User.where("name LIKE ?", "%#{@query}%")
                 .where.not(id: current_user.id)
                 .where.not(role: "admin")
                 .where.not(email: "guest@example.com")
    render :index
  end

  def report
    @user = User.find(params[:id])
    @user.update(reported: true) # ユーザーを「通報済み」にする
    redirect_to user_path(@user), notice: "このユーザーを通報しました。"
  end

  def daily_reports
    @daily_reports = DailyReport.where(user_id: params[:id])

    respond_to do |format|
      format.html
      format.json do
        render json: @daily_reports.map do |report|
          {
            title: report.title,
            start: report.date.iso8601,
            description: report.content,
            user: report.user.name
          }
        end  # JSON のレスポンスに description や user を含め、拡張性を確保
      end    # フロントエンド側でより多くの情報が扱えるように
    end
  end

  def skill_growth_data
    # ここでは current_user が持つ、スキルの進捗履歴を JSON で返す例
    skill_data = current_user.skill_progress.map { |s| { date: s.date.iso8601, level: s.level } } rescue []
    render json: skill_data
  end

  def activity_data
    # 現在のアクティビティデータを集計して返す
    activities = current_user.activities.map { |a| { category: a.category, value: a.value } } rescue []
    render json: activities
  end

  private

  # ここで、投稿がグループ投稿の場合にフィルタする
  # もし投稿の group が存在し、かつそのグループの privacy が "restricted_visibility" で、
  # 現在のユーザーがそのグループのメンバーでない場合、その投稿を除外。
  def filter_posts(posts)
    posts.reject do |post|
      post.group.present? &&
        post.group.restricted_visibility? &&
        !post.group.users.include?(current_user)
    end
  end

  def user_params
    params.require(:user).permit(:name, :email, :personal_statement, :growth_story, :portfolio_url, :portfolio_file, :profile_image, :daily_reports_public)
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