class Public::GroupsController < ApplicationController
  before_action :authenticate_user!
  before_action :reject_guest_write, except: %i[index show]



  def index
    # デフォルトは「すべて」＝公開とメンバーのみ
    default_privacy = ["public_visibility", "restricted_visibility"]
  
    if params[:privacy].present?
      # もしフォームで「公開」または「メンバーのみ」が選ばれているならその値で絞り込む
      @groups = Group.where(privacy: params[:privacy])
    else
      # 何も選択されていなければデフォルトで両方表示する
      @groups = Group.where(privacy: default_privacy)
    end
  
    # 検索キーワードによる絞り込み（グループ名または説明）
    @query = params[:query]
    if @query.present?
      normalized_query = @query.tr('ァ-ン', 'ぁ-ん').downcase
      @groups = @groups.where(
        "(LOWER(name) LIKE ? OR LOWER(description) LIKE ?)",
        "%#{@query.downcase}%",
        "%#{normalized_query}%"
      )
    end

    @groups = @groups.order(created_at: :desc)
                     .includes(:memberships)
  
    # ログイン済みの場合は参加中のグループを取得
    if user_signed_in?
      @joined_groups = Group.joins(:memberships)
                            .where(memberships: { user_id: current_user.id, role: ["member", "owner"] })
                            .includes(:memberships)
    else
      @joined_groups = Group.none
    end
  
    # 人気グループ（公開＋メンバーのみを対象）
    @popular_groups = Group.where(privacy: default_privacy)
                           .joins(:memberships)
                           .group('groups.id')
                           .order('COUNT(memberships.id) DESC')
                           .limit(6)
  end

  def show
    @group = Group.find(params[:id])
    @user = @group.owner
    @membership = current_user.memberships.find_by(group: @group)
  
    # ページネーション用の投稿一覧
    @posts = @group.posts.order(created_at: :desc).page(params[:page]).per(10)
  
    # 最近のアクティビティ用（最新5件の投稿）
    @recent_posts = @group.posts.order(created_at: :desc).limit(5)
  
    # 承認待ちの参加リクエスト（オーナー管理タブ用）
    # 承認待ちのメンバーは、@group.memberships のうち role が "pending" のもの (オーナーIDは除外)
    @pending_members = @group.memberships.where(role: "pending").where.not(user_id: @group.owner_id)
  
    # 所有グループ一覧（オーナー管理タブ用）
    # current_user がオーナーの場合、所有しているグループ一覧を取得
    @owned_groups = current_user.owned_groups
  
    # Membership 経由で、role が "member" または "owner" のユーザーを取得（最新3件）
    @new_members = @group.memberships.where(role: ["member", "owner"])
                                    .order(created_at: :desc)
                                    .limit(3)
                                    .map(&:user)
  
    session[:return_to] = request.original_url
  end

  def new
    @group = Group.new
  end

  def create
    @user = User.find(params[:user_id])
    @group = @user.groups.new(group_params)
  
    # 一般ユーザーの場合、所有者は作成者に設定する
    @group.owner = current_user
    @group.category = "user_created_label" unless current_user.admin?
  
    if @group.save
      # グループ作成後、オーナーとしてメンバーシップを作成（role: "owner"）
      @group.memberships.create(user: current_user, role: "owner")
      redirect_to group_path(@group), notice: "グループを作成しました！"
    else
      Rails.logger.error "Group creation failed: #{@group.errors.full_messages.join(", ")}"
      flash.now[:alert] = "グループ作成に失敗しました: #{@group.errors.full_messages.join(", ")}"
      render :new
    end
  end

  def edit
    @group = Group.find(params[:id])
  end

  def update
    @group = Group.find(params[:id])
    if @group.update(group_params)
      redirect_to group_path(@group), notice: "グループ情報を更新しました！"
    else
      render :edit
    end
  end

  def request_join
    @group = Group.find(params[:id])
    @user = current_user

    if current_user.guest_user?
      return redirect_to group_path(@group),
                         alert: "ゲストユーザーはグループに参加できません。"
    end


    membership = @group.memberships.find_by(user: @user)
    if membership&.role == "member"
      return redirect_to group_path(@group), alert: "すでにメンバーとして参加済みです！"
    elsif membership&.role == "pending"
      return redirect_to group_path(@group), alert: "すでに参加リクエストを送信済みです！"
    end

    # invite_only や admin_only の場合は pending を適用
    role = %w[invite_only admin_only].include?(@group.join_policy) ? "pending" : "member"
    # ※ ここで :role に値を渡す
    @group.memberships.create!(user: @user, role: role)
    notice_message = role == "pending" ? "参加リクエストを送信しました。管理者の承認を待っています。" : "グループに参加しました！"
    redirect_to group_path(@group), notice: notice_message
  end

  def leave
    @group = Group.find(params[:id])
    # 退会も reject_guest_write が先に評価されるのでここでは特に不要
    membership = current_user.memberships.find_by(group: @group)
    if membership
      membership.destroy
      redirect_to groups_path, notice: "グループを退会しました"
    else
      redirect_to group_path(@group), alert: "グループに所属していません"
    end
  end


  def destroy
    @group = Group.find(params[:id])
    if @group.destroy
      redirect_to groups_path, notice: "グループを削除しました"
    else
      redirect_to group_path(@group), alert: "グループを削除できませんでした"
    end
  end

  def search
    @query = params[:query]
    if @query.present?
      @groups = Group.where("name LIKE ?", "%#{@query}%")
      @groups = @groups.or(Group.where("category LIKE ?", "%#{@query}%"))
      @groups = @groups.where(privacy: "public_visibility")
    else
      @groups = Group.none
    end
  end

  def report
    @group = Group.find_by(id: params[:id])
    unless @group
      redirect_to groups_path, alert: "指定されたグループが見つかりませんでした"
      return
    end
  
    if @group.reported?
      redirect_to group_path(@group), alert: "このグループはすでに通報済みです"
      return
    end

    # 「admin@example.com」のアカウントを統一して使用
    admin = User.find_by(email: 'admin@example.com')
    unless admin
      admin = User.create!(
        email: 'admin@example.com',
        password: SecureRandom.urlsafe_base64,
        name: '管理者'
      )
    end
  
    if @group.update(reported: true)
      Notification.create!(
        user: admin,
        source: current_user,
        notification_type: :group_reported
      )
      redirect_to group_path(@group), notice: "グループを通報しました"
    else
      redirect_to group_path(@group), alert: "通報処理に失敗しました"
    end
  end
  
  def manage_group
    @group = Group.find(params[:id])
    unless current_user == @group.owner
      return redirect_to group_path(@group), alert: "この操作はグループオーナーのみ可能です。"
    end
  
    # 保留中の参加リクエストを取得
    @pending_members = @group.memberships.where(role: "pending")
    # show 画面で利用している他の変数もセットする
    @posts = @group.posts.order(created_at: :desc).page(params[:page]).per(10)
    @recent_posts = @group.posts.order(created_at: :desc).limit(5)
    @new_members = @group.memberships.where(role: ["member", "owner"])
                                     .order(created_at: :desc)
                                     .limit(3)
                                     .map(&:user)
    
    # これで、show テンプレート内で参照されるすべての変数が定義されるのでエラーは解消される
    render :show
  end

  def approve_membership
    @membership = Membership.find(params[:id])
    @group = @membership.group
    if @group.join_policy == "admin_approval"
      return redirect_to group_path(@group), alert: "この操作は管理者のみ可能です。" unless current_user.admin?
    elsif @group.join_policy == "owner_approval"
      return redirect_to group_path(@group), alert: "この操作はグループオーナーのみ可能です。" unless current_user == @group.owner
    else
      return redirect_to manage_group_path(@group), alert: "権限がありません" unless current_user == @group.owner
    end

    # "status" ではなく "role" をチェックして更新
    if @membership.role == "pending"
      @membership.update!(role: "member")
      redirect_to group_path(@group), notice: "参加リクエストを承認しました！"
    else
      redirect_to group_path(@group), alert: "このユーザーはすでにメンバーです！"
    end
  end

  def reject_membership
    @membership = Membership.find(params[:id])
    unless current_user == @membership.group.owner
      return redirect_to manage_group_path(@membership.group), alert: "権限がありません"
    end
    @membership.destroy
    redirect_to manage_group_path(@membership.group), notice: "参加リクエストを拒否しました！"
  end

  def owner_dashboard
    @owned_groups = Group.where(owner_id: current_user.id)
  end

  private

  def already_reported?(group)
    group.reported?
  end

  # メールアドレスが guest@example.com の自動ログインユーザーだけを制限
  def reject_guest_write
    if current_user&.guest_user?
      redirect_to users_mypage_path,
                  alert: "ゲストユーザーはこの操作を実行できません。"
    end
  end

  def group_params
    params.require(:group).permit(:name, :privacy, :join_policy, :location, :description, :group_image, :category)
  end
end