class Admin::GroupsController < ApplicationController
  before_action :authenticate_admin!
  layout 'admin'

  def index
    @groups = Group.all
  
    # 検索処理：ビュー側のパラメータは :query なのでこちらを利用
    if params[:query].present?
      @groups = @groups.where("name LIKE ? OR description LIKE ?", "%#{params[:query]}%", "%#{params[:query]}%")
    end
  
    # 通報済みグループのみフィルタ
    if params[:reported_only] == "true"
      @groups = @groups.where(reported: true)
    end
  
    # プライバシーによるフィルタ（もし選択されているなら）
    if params[:privacy].present?
      @groups = @groups.where(privacy: params[:privacy])
    end
  
    # カテゴリによるフィルタ（もし使うなら、例として category パラメータをチェック）
    if params[:category].present?
      @groups = @groups.where(category: params[:category])
    end
  
    # ソート処理
    if params[:sort] == "newest"
      @groups = @groups.order(created_at: :desc)
    elsif params[:sort] == "oldest"
      @groups = @groups.order(created_at: :asc)
    end
  
    flash.now[:alert] = "該当するグループがありません。" if @groups.empty?
  end

  def show
    @group = Group.find(params[:id])
    @memberships = @group.memberships
                         .where(role: %w[member owner])
                         .joins(:user)
                         .includes(:user)
    @pending_memberships = @group.memberships
                                 .where(role: :pending)
                                 .where.not(user_id: @group.owner_id)
                                 .joins(:user)
                                 .includes(:user)
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