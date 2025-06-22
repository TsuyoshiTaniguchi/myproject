class Admin::MembershipsController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_group
  before_action :set_membership, only: %i[destroy approve reject report unreport_member]

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

  # PATCH /admin/groups/:group_id/memberships/:id/approve
  # PATCH /admin/groups/:group_id/memberships/:id/approve
  def approve
    return redirect_to(admin_group_path(@group), alert: "該当申請が見つかりません") unless @membership
    # 権限チェックは省略…

    if @membership.pending?
      # ここでモデルの approve! を呼ぶと、role 更新 + 通知生成までやってくれる
      @membership.approve!
      redirect_to admin_group_path(@group), notice: "参加リクエストを承認しました！"
    else
      redirect_to admin_group_path(@group), alert: "このユーザーはすでにメンバーです。"
    end
  end

  

  # DELETE /admin/groups/:group_id/memberships/:id/reject
  def reject
    return redirect_to(admin_group_path(@group), alert: "該当申請が見つかりません") unless @membership

    # モデルの reject! を呼ぶと、通知生成 + レコード削除までやってくれる
    @membership.reject!
    redirect_to admin_group_path(@group), notice: "参加リクエストを拒否しました。"
  end


  private

  def set_group
    @group = Group.find_by(id: params[:group_id])
    return if @group

    redirect_to admin_groups_path, alert: "グループが見つかりません。"
  end

  def set_membership
    @membership = @group.memberships.find_by(id: params[:id])
  end

end
