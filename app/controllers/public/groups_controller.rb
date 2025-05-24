class Public::GroupsController < ApplicationController

  before_action :authenticate_user!

  def index
    @groups = Group.all
  end

  def show
    @group = Group.find(params[:id])
  end

  def new
    @group = Group.new
  end

  def create
    @group = Group.new(group_params)
    @group.category = "user_created"  # ✅ `type` → `category` に変更！
    @group.owner = current_user  # ✅ 所有者を設定
  
    if @group.save
      redirect_to group_path(@group), notice: "グループを作成しました！"
    else
      render :new
    end
  end
  
end