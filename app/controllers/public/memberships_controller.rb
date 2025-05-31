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
        notification_type: "group_request_pending",
        message: "📝 ユーザー #{current_user.name} が「#{@group.name}」への参加をリクエストしました！"
      )
  
      redirect_to group_path(@group), notice: "参加リクエストを送信しました！"
    else
      redirect_to group_path(@group), alert: "参加リクエストの送信に失敗しました。"
    end
  end

  def destroy
    @membership = Membership.find_by(user: current_user, group_id: params[:group_id])

    if @membership.destroy
      redirect_to user_group_path(current_user, @membership.group), notice: "グループを脱退しました。" 
    else
      redirect_to user_group_path(current_user, @membership.group), alert: "脱退できませんでした。" 
    end
  end

  def update
    @membership = Membership.find(params[:id])
  
    if @membership.update(status: "approved")
      #  承認時にユーザーへ通知
      Notification.create(
        recipient: @membership.user, # 申請したユーザーに通知
        sender: @membership.group.admin,
        notification_type: "group_request_approved",
        message: " 「#{@membership.group.name}」への参加が承認されました！"
      )
  
      redirect_to group_path(@membership.group), notice: "参加リクエストを承認しました！"
    else
      redirect_to group_path(@membership.group), alert: "承認に失敗しました。"
    end
  end

end