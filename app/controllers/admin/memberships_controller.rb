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
    
    # 管理者は承認処理をスキップ
    if current_admin.present?
      redirect_to admin_group_path(@membership.group), notice: "管理者は承認する必要がありません。"
      return
    end

    # 「pending」の場合だけ role を「member」に更新
    if @membership.update(role: "member")
      redirect_to admin_group_path(@membership.group), notice: "参加リクエストを承認しました！"
    else
      redirect_to admin_group_path(@membership.group), alert: "承認に失敗しました。"
    end
  end
  
  def reject
    @membership = Membership.find_by(id: params[:id])
    
    # 管理者は拒否処理をスキップ
    if current_admin.present?
      redirect_to admin_group_path(@membership.group), notice: "管理者は拒否する必要がありません。"
      return
    end

    if @membership.destroy
      redirect_to admin_group_path(@membership.group), notice: "参加リクエストを拒否しました！"
    else
      redirect_to admin_group_path(@membership.group), alert: "拒否に失敗しました。"
    end
  end
end