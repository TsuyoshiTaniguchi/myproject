class Public::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :restrict_guest_access, only: [:edit, :update, :withdraw]
  before_action :set_user, only: [:edit, :update, :mypage, :show, :withdraw]



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
    @daily_reports = @user.daily_reports.order(date: :desc).page(params[:page]).per(10)

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

  MAX_PORTFOLIO_FILES = 5

  def update
    # 0) 削除チェックされたファイルがあれば先に purge
    if params[:user][:remove_portfolio_file_ids].present?
      params[:user].delete(:remove_portfolio_file_ids).each do |blob_id|
        attachment = @user.portfolio_files.find_by(blob_id: blob_id)
        attachment&.purge_later
      end
    end

    # 1) 追加分ファイルを取得して params から除去（update時に渡さない）
    new_files = params[:user].delete(:portfolio_files) || []

    # 2) プロフィールその他属性を更新
    if @user.update(user_update_params)
      # 3) 属性更新が成功したら、件数チェックしてから新規ファイルだけ attach
      if new_files.any?
        total_after = @user.portfolio_files.count + new_files.size
        if total_after <= MAX_PORTFOLIO_FILES
          @user.portfolio_files.attach(new_files)
        else
          # 超過していたらエラー
          flash.now[:alert] = "ポートフォリオは最大#{MAX_PORTFOLIO_FILES}件までです。現在#{@user.portfolio_files.count}件、追加#{new_files.size}件で合計#{total_after}件は登録できません。"
          return render :edit
        end
      end

      redirect_to user_path(@user), notice: "プロフィールが更新されました。"
    else
      render :edit, alert: "更新に失敗しました。"
    end
  end


  def show
    @user            = User.find(params[:id])
    @following_users = @user.following

    # 投稿フィルタリング（既存ロジック）
    own_posts          = filter_posts(@user.posts.to_a)
    followed_user_ids  = current_user.following.pluck(:id)
    followed_posts     = filter_posts(Post.where(user_id: followed_user_ids).to_a)
    @posts             = (own_posts + followed_posts).sort_by(&:created_at).reverse

    # ここから日報ロジック
    # “自分のと公開済み”だけ accessible_for で拾い、
    # 日報は公開／非公開を問わず“全部”取得してページネート
    @daily_reports = @user.daily_reports
                          .order(date: :desc)
                          .page(params[:page])
                          .per(10)
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
    if @user.reported?
      redirect_to user_path(@user), alert: "このユーザーは既に通報されています"
    else
      @user.update!(reported: true)
      # サイト管理者に通知を飛ばす
      Notification.create!(
        user:              User.find_by(email: ENV.fetch("ADMIN_EMAIL")),
        source:            current_user,
        notification_type: :member_report
      )
      redirect_to user_path(@user), notice: "ユーザーを通報しました"
    end
  end


  def daily_reports
    # 1) @userをIDから取得
    @user = User.find(params[:id])

    # 2) アクセス制御済みレポートを日付降順で取得
    reports = DailyReport
                .accessible_for(current_user, @user.id)
                .order(date: :desc)

    # 3) Kaminariで10件ずつページネート（HTML用）
    @daily_reports = reports.page(params[:page]).per(10)

    respond_to do |format|
      format.html
      format.json do
        # カレンダー用JSONはページネートせず全件返す
        events = reports.map do |r|
          {
            id:          r.id,
            title:       r.location.presence || r.content.truncate(30),
            start:       r.date.iso8601,
            description: r.content,
            user:        r.user.name,
            # 自分のページなら show、それ以外は compact に誘導
            url:         (@user == current_user) ?
                           daily_report_path(r) :
                           compact_daily_report_path(r)
          }
        end

        render json: events
      end
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

  def set_user
    @user = current_user
  end

  # portfolio_files, remove_portfolio_file_ids はここでは permit しない
  # ポートフォリオ用ファイル関連はここではpermitせず、
  # attach/purgeは上記ロジックで行う
  def user_update_params
    params.require(:user).permit(
      :name,
      :email,
      :personal_statement,
      :growth_story,
      :daily_reports_public,
      :portfolio_url,
      :profile_image
    )
  end



  def ensure_guest_user
    @user = User.find(params[:id])
    if @user.guest_user?
      redirect_to user_path(current_user), notice: "ゲストユーザーはプロフィール編集画面へ遷移できません。"
    end
  end

  def restrict_guest_access
    if current_user&.guest_user?
      redirect_to users_mypage_path,
                  alert: "ゲストユーザーはこの操作を実行できません。"
    end
  end

end