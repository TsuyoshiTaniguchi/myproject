class Public::MembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_membership, only: [:report_member]

  def create
    @group = Group.find(params[:group_id])
    # role で状態を管理する場合
    @membership = @group.memberships.build(user: current_user, role: "pending")
    
    if @membership.save
      # 承認リクエスト時に管理者へ通知（ここはグループオーナーもしくは管理者を設定）
      Notification.create(
        recipient: @group.owner,   # グループの所有者（または「admin」メソッドが定義済みであればそちら）
        sender: current_user,
        notification_type: "group_request_pending"
      )
      redirect_to group_path(@group), notice: "参加リクエストを送信しました！"
    else
      redirect_to group_path(@group), alert: "参加リクエストの送信に失敗しました。"
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
        recipient: @membership.user, # 申請したユーザーに通知
        sender: @membership.group.owner,
        notification_type: "group_request_approved"
      )
      redirect_to group_path(@membership.group), notice: "参加リクエストを承認しました！"
    else
      redirect_to group_path(@membership.group), alert: "承認に失敗しました。"
    end
  end

  def report
    @membership = Membership.find(params[:id])
    if @membership.update(reported: true)
      Notification.create(
        recipient: Admin.first,  # 管理者へ通知
        sender: current_user,
        notification_type: "admin_alert"
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
    @membership = Membership.find(params[:id])
    @group = @membership.group || Group.find(params[:group_id])
    
    if @membership.role == "pending"
      @membership.update!(role: "member")
      # 管理者に対して通知。ここも同じキーを利用して統一
      admin = Admin.first
      Notification.create(
        recipient: admin,
        sender: current_user,
        notification_type: "group_membership_approved"
      )
      redirect_to group_path(@group), notice: "参加リクエストを承認しました！"
    else
      redirect_to group_path(@group), alert: "このユーザーはすでにメンバーです！"
    end
  end
  
  def reject_membership
    @membership = Membership.find_by(id: params[:id])
    unless @membership.present?
      redirect_to groups_path, alert: "指定された参加リクエストは存在しません。"
      return
    end

    if @membership.destroy
      redirect_to manage_group_group_membership_path(@membership.group, @membership), notice: "参加リクエストを拒否しました！"
    else
      redirect_to manage_group_group_membership_path(@membership.group, @membership), alert: "拒否に失敗しました。"
    end
  end

  def owner_dashboard
    @owned_groups = Group.where(owner_id: current_user.id)
    render "public/groups/owner_dashboard"
  end

  private

  # 共通処理として、report_member 用に @membership を取得
  def set_membership
    @membership = Membership.find_by(id: params[:id])
  end

  # 通報処理の共通メソッド
  def process_member_report(membership, notification_type)
    if membership.update(reported: true)
      Notification.create(
        recipient: Admin.first,
        sender: current_user,
        notification_type: notification_type
      )
      redirect_to group_path(membership.group), notice: "メンバーを通報しました"
    else
      redirect_to group_path(membership.group), alert: "このメンバーはすでに通報されています"
    end
  end
end