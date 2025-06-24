class Public::MembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_group,      only: [:create, :destroy, :approve_membership, :reject_membership]
  before_action :set_membership, only: [:approve_membership, :reject_membership, :report_member]

  def create
    @membership = @group.memberships.build(user: current_user, role: :pending)
    if @membership.save
      # Notification.create は model の after_create に任せる
      redirect_to @group, notice: "参加リクエストを送信しました！"
    else
      redirect_to @group, alert: "申請に失敗しました。"
    end
  end

  def destroy
    @membership = Membership.find_by(user: current_user, group_id: params[:group_id])
    if @membership.nil?
      redirect_to groups_path, alert: "グループに所属していません！"
      return
    end

    if @membership.destroy
      redirect_to groups_path, notice: "グループを脱退しました。"
    else
      redirect_to group_path(@membership.group), alert: "脱退できませんでした。"
    end
  end

  def update
    @membership = Membership.find(params[:id])
    # 承認時は role を「member」に更新する
    if @membership.update(role: "member")
      Notification.create(
        user_id: @membership.user.id,           # 申請したユーザーが受け取る通知
        source_id: @membership.group.owner.id,    # 承認を実施した（グループの所有者）ユーザーが発信者
        source_type: "User",
        notification_type: :membership_approval  # enumに合わせて通知種別を変更
      )
      redirect_to group_path(@membership.group), notice: "参加リクエストを承認しました！"
    else
      redirect_to group_path(@membership.group), alert: "承認に失敗しました。"
    end
  end
  

  def report
    @membership = Membership.find(params[:id])
    if @membership.update(reported: true)
      admin = User.find_by(email: 'admin@example.com')
      unless admin
        admin = User.create!(
          email: 'admin@example.com',
          password: SecureRandom.urlsafe_base64,
          name: '管理者'
        )
      end
      Notification.create!(
        user: admin,
        source: current_user,
        notification_type: :admin_alert  # ここは用途に合わせた通知種別に
      )
      redirect_to group_path(@membership.group), notice: "メンバーを通報しました"
    else
      redirect_to group_path(@membership.group), alert: "このメンバーはすでに通報されています"
    end
  end
  
  


  # メンバーの通報処理
  def report_member
    if @membership.nil?
      redirect_to groups_path, alert: "指定されたメンバーが見つかりませんでした"
      return
    end

    process_member_report(@membership, "member_reported")
  end

  def manage_group
    @group = Group.find_by(id: params[:group_id])
    unless @group.present?
      redirect_to groups_path, alert: "指定されたグループは存在しません。"
      return
    end

    unless current_user == @group.owner
      redirect_to group_path(@group), alert: "グループの管理権限がありません。"
      return
    end

    @pending_members = @group.memberships.where(role: "pending")
    Rails.logger.debug "🔍 @group: #{@group.inspect}"
    Rails.logger.debug "🔍 @pending_members: #{@pending_members.inspect}"

    respond_to do |format|
      format.html { render "public/groups/manage_group" }
      format.json { render json: @pending_members }
    end
  end

  def approve_membership
    if @membership.pending?
      @membership.approve!    # Membership#approve! によって role を "member" に変更し、通知作成を行う
      redirect_to @group, notice: "参加リクエストを承認しました！"
    else
      redirect_to @group, alert: "すでにメンバーです。"
    end
  end
  
  def reject_membership
    if @membership.pending?
      @membership.reject!      
      redirect_to manage_group_group_path(@group), notice: "参加リクエストを拒否しました！"
    else
      redirect_to manage_group_group_path(@group), alert: "処理できませんでした。"
    end
  end

  def owner_dashboard
    @owned_groups = Group.where(owner_id: current_user.id)
    render "public/groups/owner_dashboard"
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
  end

  # 共通処理として、report_member 用に @membership を取得
  def set_membership
    @membership = @group.memberships.find_by(id: params[:id])
    unless @membership
      redirect_to @group, alert: "該当のメンバーシップが見つかりません" and return
    end
  end

  # 通報処理の共通メソッド
  def process_member_report(membership, notification_type)
    if membership.update(reported: true)
      Notification.create(
        user_id: Admin.first.id,
        source_id: current_user.id,
        source_type: "User",
        notification_type: notification_type
      )
      redirect_to group_path(membership.group), notice: "メンバーを通報しました"
    else
      redirect_to group_path(membership.group), alert: "このメンバーはすでに通報されています"
    end
  end
end
