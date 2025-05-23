class Public::MembershipsController < ApplicationController
  before_action :authenticate_user!

  def create
    @group = Group.find(params[:group_id])
    @membership = Membership.new(user: current_user, group: @group, role: "member")
    
    if @membership.save
      redirect_to group_path(@group), notice: "#{@group.name} に参加しました！"
    else
      redirect_to group_path(@group), alert: "参加できませんでした。"
    end
  end

  def destroy
    @membership = Membership.find_by(user: current_user, group_id: params[:group_id])
    
    if @membership.destroy
      redirect_to group_path(params[:group_id]), notice: "グループを脱退しました。"
    else
      redirect_to group_path(params[:group_id]), alert: "脱退できませんでした。"
    end
  end
end
