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
end