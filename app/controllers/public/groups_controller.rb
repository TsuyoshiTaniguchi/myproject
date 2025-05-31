class Public::GroupsController < ApplicationController
  before_action :authenticate_user!
  before_action :restrict_guest_access, only: [:create]

  def index
    @user = User.find(params[:user_id])
    @groups = Group.where(id: @user.memberships.pluck(:group_id))  # ✅ 
    @query = params[:query] # 検索キーワードを取得
  
    if @query.present?
      normalized_query = @query.tr('ァ-ン', 'ぁ-ん').downcase
      
      @groups = Group.where("LOWER(name) LIKE ?", "%#{@query.downcase}%")
               .or(Group.where("LOWER(name) LIKE ?", "%#{normalized_query}%"))
               .where(privacy: ["public_visibility", "restricted_visibility"])
    else
      @groups = @user.groups.includes(:memberships)  #  関連データを読み込む
    end
  end

  def show
    @group = Group.find(params[:id])
    @user = User.find_by(id: params[:user_id])  #  `find_by` ならエラーにならず nil を返す
    @membership = current_user.memberships.find_by(group: @group)

    session[:return_to] = request.original_url
  end
  
  def new
    @group = Group.new
  end

  def create
    @user = User.find(params[:user_id])
    @group = @user.groups.new(group_params) # `@user.groups.new` でネストを考慮
  
    @group.category = "user_created_label" 
  
    if @group.save
      @group.memberships.create(user: current_user, role: "owner") # オーナー登録
      @group.update(owner_id: current_user.id) # 所有者を明示的に設定
  
      redirect_to user_group_path(@user, @group), notice: "グループを作成しました！"
    else
      render :new
    end
  end
  
  def edit
    @group = Group.find(params[:id])
  end

  def update
    @group = Group.find(params[:id])
  
    if @group.update(group_params)
      redirect_to user_group_path(current_user, @group), notice: "グループ情報を更新しました！"
    else
      render :edit
    end
  end

  def request_join
    @group = Group.find(params[:id])
    @user = current_user
  
    if @user.guest?
      redirect_to user_group_path(@group), alert: "ゲストユーザーはグループに参加できません。"
      return
    end
  
    # すでにメンバーかチェック
    membership = @group.memberships.find_by(user: @user)
  
    if membership&.role == "member"
      redirect_to user_group_path(@group), alert: "すでにメンバーとして参加済みです！"
      return
    elsif membership&.role == "pending"
      redirect_to user_group_path(@group), alert: "すでに参加リクエストを送信済みです！"
      return
    end
  
    # `public_visibility` の場合は直接参加OK
    if @group.privacy == "public_visibility"
      @group.memberships.create!(user: @user, role: "member")
      redirect_to user_group_path(@group), notice: "グループに参加しました！"
      return
    end
  
    # `restricted_visibility` の場合はリクエストを送信
    @group.memberships.create!(user: @user, role: "pending")
    redirect_to user_group_path(@group), notice: "参加リクエストを送信しました！"
  end
  

  def leave
    @group = Group.find(params[:id])
    @membership = current_user.memberships.find_by(group: @group)
  
    if @membership
      @membership.destroy
      redirect_to user_groups_path(current_user), notice: "グループを退会しました"
    else
      redirect_to user_group_path(current_user, @group), alert: "グループに所属していません"
    end
  end

  def search
    @query = params[:query]
  
    if @query.present?
      @groups = Group.where("name LIKE ?", "%#{@query}%")
      
      # カテゴリでも検索可能に
      @groups = @groups.or(Group.where("category LIKE ?", "%#{@query}%"))
  
      # 公開グループのみ表示（オプション）
      @groups = @groups.where(privacy: "public_visibility")
    else
      @groups = Group.none # 検索なしの場合、空リストを返す
    end
  end



  
  def destroy
    @group = Group.find(params[:id])
  
    if @group.destroy
      redirect_to user_groups_path(current_user), notice: "グループを削除しました"
    else
      redirect_to user_group_path(current_user, @group), alert: "グループを削除できませんでした"
    end
  end

  private

  def group_params
    params.require(:group).permit(:name, :privacy, :join_policy, :location, :description, :group_image, :category)
  end
  
end