class Admin::MembershipsController < ApplicationController
  before_action :authenticate_admin!

  def create
    @group = Group.find(params[:group_id])
    @user = User.find(params[:user_id])
    @membership = Membership.new(user: @user, group: @group, role: params[:role] || "member")
    
    if @membership.save
      redirect_to admin_group_path(@group), notice: "#{@user.name} をグループに追加しました！"
    else
      redirect_to admin_group_path(@group), alert: "追加できませんでした。"
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