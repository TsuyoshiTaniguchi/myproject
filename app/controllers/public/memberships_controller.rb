class Public::MembershipsController < ApplicationController
  before_action :authenticate_user!

  def create
    @group = Group.find(params[:group_id])
    @membership = @group.memberships.build(user: current_user, status: "pending")

    if @membership.save
      # 承認リクエスト時に管理者へ通知
      Notification.create(
        recipient: @group.admin, # グループ管理者へ通知
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

    if @membership.update(status: "approved")
      # 承認時にユーザーへ通知
      Notification.create(
        recipient: @membership.user, # 申請したユーザーに通知
        sender: @membership.group.admin,
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
      # 通報時に管理者へ通知！
      Notification.create(
        recipient: Admin.first, # 管理者へ通知！
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
  
    #  デバッグログを追加して、データを確認
    Rails.logger.debug "🔍 @group: #{@group.inspect}"
    Rails.logger.debug "🔍 @pending_members: #{@pending_members.inspect}"
  
    respond_to do |format| 
      format.html { render "public/groups/manage_group" } 
      format.json { render json: @pending_members }
    end
  end

  def approve_membership
    @membership = Membership.find(params[:id])
    # まず、Membership 経由で関連するグループを取得
    @group = @membership.group
    # 万が一 @group が nil なら、params[:group_id] を使って取得
    @group ||= Group.find(params[:group_id])
  
    if @membership.role == "pending"
      @membership.update!(role: "member")
  
      # 管理者 (admin) を取得する処理（ここは以前の修正済み）
      admin = Admin.first
      Notification.create(
        user_id: admin.id,
        source_id: current_user.id,
        source_type: "User",
        notification_type: "group_membership_approved"
      )
      redirect_to group_path(@group), notice: "参加リクエストを承認しました！"
    else
      redirect_to group_path(@group), alert: "このユーザーはすでにメンバーです！"
    end
  end
  
  def reject_membership
    @membership = Membership.find_by(id: params[:id]) # `find_by` に変更して安全な処理に
  
    unless @membership.present? # 誤った `id` の場合にエラーハンドリング
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
    @owned_groups = Group.where(owner_id: current_user.id) # ✅ オーナーのグループのみ取得
  
    render "public/groups/owner_dashboard"
  end

  private

  # `@membership` を取得する共通処理
  def set_membership
    @membership = Membership.find_by(id: params[:id])
  end

  # 通報処理の共通メソッド
  def process_member_report(membership, notification_type)
    if membership.update(reported: true)
      # 通報時に管理者へ通知
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