class Admin::MembershipsController < ApplicationController
  before_action :authenticate_admin!

  def create
    begin
      @group = Group.find(params[:group_id])
      @user = User.find(params[:user_id])
  
      # すでにメンバーかチェック
      if @group.memberships.exists?(user: @user)
        redirect_to admin_group_path(@group, anchor: "members"), alert: "#{@user.name} はすでにメンバーです！"
        return
      end
  
      @membership = @group.memberships.create(user: @user, role: params[:role] || "member")
  
      if @membership.persisted?
        redirect_to admin_group_path(@group, anchor: "members"), notice: "#{@user.name} をグループに追加しました！"
      else
        redirect_to admin_group_path(@group, anchor: "members"), alert: "追加できませんでした。"
      end
  
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_groups_path, alert: "対象のグループまたはユーザーが見つかりませんでした。"
    end
  end

  def destroy
    @membership = Membership.find(params[:id])

    if @membership.destroy
      redirect_to admin_group_path(@membership.group), notice: "メンバーを削除しました。"
    else
      redirect_to admin_group_path(@membership.group), alert: "削除できませんでした。"
    end
  end

  def approve
    @membership = Membership.find(params[:id])
    
    if @membership.update(status: "approved")
      Notification.create(
        recipient: @membership.user, # 申請したユーザーへ通知！
        sender: @membership.group.admin,
        notification_type: "group_request_approved",
        message: "✅ 「#{@membership.group.name}」への参加が承認されました！"
      )
      redirect_to admin_group_path(@membership.group), notice: "参加リクエストを承認しました！"
    else
      redirect_to admin_group_path(@membership.group), alert: "承認に失敗しました。"
    end
  end
  
  def reject
    @membership = Membership.find(params[:id])
    
    if @membership.destroy
      Notification.create(
        recipient: @membership.user, # 申請したユーザーへ通知
        sender: @membership.group.admin,
        notification_type: "group_request_rejected",
        message: "❌ 「#{@membership.group.name}」への参加が拒否されました！"
      )
      redirect_to admin_group_path(@membership.group), notice: "参加リクエストを拒否しました！"
    else
      redirect_to admin_group_path(@membership.group), alert: "拒否に失敗しました。"
    end
  end

end