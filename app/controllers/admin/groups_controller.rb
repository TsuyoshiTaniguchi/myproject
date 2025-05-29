class Admin::GroupsController < ApplicationController
  before_action :authenticate_admin!

  def index
    @groups = Group.all
  
    if params[:search].present?
      @groups = @groups.where("name LIKE ?", "%#{params[:search]}%") # グループ名で検索
    end
  end

  def show
    @group = Group.find(params[:id])
  end

  def new
    @group = Group.new
  end


  def edit
    @group = Group.find(params[:id])
  end

  def update
    @group = Group.find_by(id: params[:id]) # 🔹 `find` → `find_by` に変更して `nil` を防ぐ
  
    if @group.nil?
      flash[:alert] = "グループが見つかりません。"
      redirect_to admin_groups_path and return
    end
  
    if @group.update(group_params)
      redirect_to admin_group_path(@group), notice: "グループ情報を更新しました！"
    else
      flash.now[:alert] = "更新に失敗しました。"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @group = Group.find(params[:id])
  
    ActiveRecord::Base.transaction do
      @group.posts.destroy_all # 投稿を削除
      @group.memberships.destroy_all # ユーザーとの関連を削除（UserGroup → Membership）
      @group.destroy
    end
  
    redirect_to admin_groups_path, notice: "グループを削除しました！"
  rescue ActiveRecord::RecordNotDestroyed
    flash[:alert] = "グループを削除できませんでした。"
    redirect_to admin_groups_path
  end

  def create
    @group = Group.new(group_params)
  
    if @group.save
      redirect_to admin_group_path(@group), notice: "#{@group.name} を作成しました！"
    else
      render :new
    end
  end

  def remove_group_image
    @group.group_image.purge
    redirect_to edit_admin_group_path(@group), notice: "画像を削除しました！"
  end
  
  
  private
  
  def group_params
    params.require(:group).permit(:name, :description, :privacy, :join_policy, :location, :category, :group_image)
  end

end