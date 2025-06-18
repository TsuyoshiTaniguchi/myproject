class Admin::GroupsController < ApplicationController
  before_action :authenticate_admin!
  layout 'admin'

  def index
    @groups = Group.all

    # 承認待ちメンバーを role: "pending" で取得し、
    # 承認済み(member)の user_id は除外する
    @pending_memberships = Membership
      .where(role: "pending")
      .where.not(user_id: Membership.where(role: "member").pluck(:user_id))
      .includes(:user, :group)

    # 検索処理
    if params[:search].present?
      @groups = @groups.where("name LIKE ?", "%#{params[:search]}%")
    end

    # 通報済みグループのみフィルタ
    if params[:reported_only] == "true"
      @groups = @groups.where(reported: true)
    end

    flash.now[:alert] = "該当するグループがありません。" if @groups.empty?
  end

  def show
    @group = Group.find(params[:id])

    # 「新しいメンバー」: role: "member" で取得
    @new_members = @group.memberships
                         .where(role: "member")
                         .order(created_at: :desc)
                         .limit(5)
                         .map(&:user)

    # 承認待ちメンバー: role: "pending" で取得、オーナーは除外
    @pending_memberships = @group.memberships
                                 .where(role: "pending")
                                 .where.not(user_id: @group.owner_id)
  end

  def new
    @group = Group.new
  end

  def edit
    @group = Group.find(params[:id])
  end

  def create
    @group = Group.new(group_params)
    unless current_admin.present?
      redirect_to admin_groups_path, alert: "公式グループは管理者のみ作成可能です！" and return
    end
  
    # ここで owner を設定。例えば、管理者の email による関係付け。
    @group.owner = User.find_by(email: current_admin.email)  # 必要に応じて調整
  
    if @group.save
      redirect_to admin_group_path(@group), notice: "#{@group.name} を作成しました！"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @group = Group.find_by(id: params[:id])
    unless @group
      redirect_to admin_groups_path, alert: "グループが見つかりません。" and return
    end

    if @group.update(group_params)
      redirect_to admin_group_path(@group), notice: "グループ情報を更新しました！"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @group = Group.find(params[:id])
    ActiveRecord::Base.transaction do
      @group.posts.destroy_all
      @group.memberships.destroy_all
      @group.destroy!
    end
    redirect_to admin_groups_path, notice: "グループを削除しました！"
  rescue ActiveRecord::RecordNotDestroyed
    redirect_to admin_groups_path, alert: "グループを削除できませんでした。"
  end

  def remove_group_image
    @group = Group.find(params[:id])
    @group.group_image.purge
    redirect_to edit_admin_group_path(@group), notice: "画像を削除しました！"
  end

  def unreport
    @group = Group.find(params[:id])
    @group.update!(reported: false)
    redirect_to admin_group_path(@group), notice: "通報を解除しました。"
  end

  private

  def group_params
    params.require(:group)
          .permit(:name, :description, :privacy, :join_policy, :location, :category, :group_image)
  end
  
end