class Admin::GroupsController < ApplicationController
  before_action :authenticate_admin!

  def index
    @groups = Group.all
    @pending_memberships = Membership.where(status: "pending").where.not(user_id: Membership.where(status: "approved").pluck(:user_id)).includes(:user, :group)

    #  検索処理: パラメータが存在する場合のみ適用
    if params[:search].present?
      @groups = @groups.where("name LIKE ?", "%#{params[:search]}%")
    end
  
    #  通報済みグループのみフィルタリング
    if params[:reported_only].present? && params[:reported_only] == "true"
      @groups = @groups.where(reported: true)
    end
  
    #  データが空にならないよう、確認
    flash.now[:alert] = "該当するグループがありません。" if @groups.empty?
  end

  def show
    @group = Group.find(params[:id])
    
    # 承認済み（member）のユーザーを最新順に取得（「新しいメンバー」）
    @new_members = @group.memberships.where(status: "member").order(created_at: :desc).limit(5).map(&:user)
  
    # 承認待ち（pending）のメンバーを取得。ここでは、オーナーが pending 状態になっている場合を除外しておく
    @pending_memberships = @group.memberships.where(status: "pending").where.not(user_id: @group.owner_id)
  end

  def new
    @group = Group.new
  end

  def edit
    @group = Group.find(params[:id])
  end

  def update
    Rails.logger.debug "📥 params received: #{params[:group].inspect}"
  
    @group = Group.find_by(id: params[:id]) # `find_by` を使用して `nil` を防ぐ
    if @group.nil?
      flash[:alert] = "グループが見つかりません。"
      redirect_to admin_groups_path and return
    end
  
    Rails.logger.debug "🔍 Before update: #{@group.attributes.inspect}"
  
    if @group.update(group_params)
      Rails.logger.debug "✅ Update successful: #{@group.attributes.inspect}"
      redirect_to admin_group_path(@group), notice: "グループ情報を更新しました！"
    else
      Rails.logger.error "❌ Update failed: #{@group.errors.full_messages.join(', ')}"
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
    Rails.logger.debug "📥 params received: #{params[:group].inspect}"
    Rails.logger.debug "🔍 Attempting to create group with category: #{params[:group][:category]}"
    
    @group = Group.new(group_params)
  
    unless current_admin.present?
      redirect_to admin_groups_path, alert: "公式グループは管理者のみ作成可能です！"
      return
    end
  
    if @group.save
      Rails.logger.debug "✅ Group created successfully: #{@group.attributes.inspect}"
      redirect_to admin_group_path(@group), notice: "#{@group.name} を作成しました！"
    else
      Rails.logger.error "❌ Group creation failed: #{@group.errors.full_messages.join(', ')}"
      render :new, status: :unprocessable_entity
    end
  end
  

  def remove_group_image
    @group.group_image.purge
    redirect_to edit_admin_group_path(@group), notice: "画像を削除しました！"
  end

  def unreport
    @group = Group.find(params[:id])
    @group.update(reported: false)
    redirect_to edit_admin_group_path(@group), notice: "通報を解除しました。"
  end

  private

  def group_params
    params.require(:group).permit(:name, :description, :privacy, :join_policy, :location, :category, :group_image)
  end

end