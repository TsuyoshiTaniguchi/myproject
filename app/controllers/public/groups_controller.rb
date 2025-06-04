class Public::GroupsController < ApplicationController
  before_action :authenticate_user!
  before_action :restrict_guest_access, only: [:create]

  def index
    # params[:user_id] が存在するかチェックし、ユーザーを取得
    @user = User.find_by(id: params[:user_id])
    @groups = @user ? Group.where(id: @user.memberships.pluck(:group_id)) : Group.all
    @joined_groups = current_user.joined_groups

    # 検索キーワードの取得
    @query = params[:query]

    if @query.present?
      # 検索を柔軟にするため、カタカナをひらがなへ変換し、小文字化
      normalized_query = @query.tr('ァ-ン', 'ぁ-ん').downcase

      # グループ名の検索（大文字小文字を区別せずマッチ）
      @groups = @groups.where("LOWER(name) LIKE ?", "%#{@query.downcase}%")
                       .or(@groups.where("LOWER(name) LIKE ?", "%#{normalized_query}%"))
                       .where(privacy: ["public_visibility", "restricted_visibility"])
    end

    @groups = @groups.includes(:memberships)

    # 参加中のグループを取得
    @joined_groups = Group.joins(:memberships)
                          .where(memberships: { user_id: current_user.id, role: "member" })
                          .includes(:memberships)

    # ★ 人気グループの取得
    @popular_groups = Group.public_visibility
                           .joins(:memberships)
                           .group('groups.id')
                           .order('COUNT(memberships.id) DESC')
                           .limit(3)

    # 既存の処理があればその後に続ける（たとえば @groups, @joined_groups など）
    end


  def show
    @group = Group.find(params[:id])
    @user = @group.owner      # グループオーナーの情報を取得
    @membership = current_user.memberships.find_by(group: @group)

    @recent_posts = @group.posts.order(created_at: :desc).limit(5)

    # Membership 経由で、role が "member" または "owner" のユーザーを取得
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

    # 公式グループは管理者のみ作成可能
    if @group.category == "official_label" && !current_user.admin?
      flash[:alert] = "公式グループは管理者のみ作成できます。"
      return render :new
    end

    # 一般ユーザーの場合、所有者は作成者に設定する
    @group.owner = current_user
    @group.category = "user_created_label" unless current_user.admin?

    if @group.save
      # グループ作成後、オーナーとしてメンバーシップを作成
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

    if @user.guest?
      return redirect_to group_path(@group), alert: "ゲストユーザーはグループに参加できません。"
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
    @membership = current_user.memberships.find_by(group: @group)
    if @membership
      @membership.destroy
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

    admin = Admin.first
    unless admin
      redirect_to group_path(@group), alert: "管理者が見つかりません"
      return
    end

    if @group.update(reported: true)
      Notification.create(
        user_id: admin.id,
        source_id: current_user.id,
        source_type: "User",
        notification_type: "group_reported"
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
    # "status" ではなく "role" で保留中の参加リクエストを取得
    @pending_members = @group.memberships.where(role: "pending")
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

  def group_params
    params.require(:group).permit(:name, :privacy, :join_policy, :location, :description, :group_image, :category)
  end
end