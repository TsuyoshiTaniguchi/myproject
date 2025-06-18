class Admin::MembershipsController < ApplicationController
  before_action :authenticate_admin!

  def create
    begin
      @group = Group.find(params[:group_id])
      @user = User.find(params[:user_id])

      # すでにメンバーかどうかチェック
      if @group.memberships.exists?(user: @user)
        redirect_to admin_group_path(@group, anchor: "members"), alert: "#{@user.name} はすでにメンバーです！"
        return
      end

      # 新規メンバー追加時は、role を「member」に設定（管理者でなければここで承認済みとして扱います）
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
    @membership = Membership.find_by(id: params[:id])
    
    unless @membership
      redirect_to admin_groups_path, alert: "ユーザー作成グループは所有者のみが承認できます。"
      return
    end
  
    # 公式グループの場合のみ、管理者が承認可能（＝グループのオーナーが管理者の場合）
    if @membership.group.owner != current_admin
      redirect_to admin_group_path(@membership.group), alert: "ユーザー作成グループは所有者のみが承認できます。"
      return
    end
  
    if @membership.pending?
      if @membership.update(role: "member")
        redirect_to admin_group_path(@membership.group), notice: "参加リクエストを承認しました！"
      else
        redirect_to admin_group_path(@membership.group), alert: "承認に失敗しました。"
      end
    else
      redirect_to admin_group_path(@membership.group), alert: "このユーザーはすでにメンバーです！"
    end
  end
  
  def reject
    @membership = Membership.find_by(id: params[:id])

    if @membership.destroy
      redirect_to admin_group_path(@membership.group), notice: "参加リクエストを拒否しました！"
    else
      redirect_to admin_group_path(@membership.group), alert: "拒否に失敗しました。"
    end
  end
  
end