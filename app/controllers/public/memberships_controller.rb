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