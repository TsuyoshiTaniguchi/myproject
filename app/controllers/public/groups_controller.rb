class Public::GroupsController < ApplicationController

  before_action :authenticate_user!

  def index
    @user = User.find(params[:user_id])
    @query = params[:query] # 検索キーワードを取得
  
    if @query.present?
      normalized_query = @query.tr('ァ-ン', 'ぁ-ん').downcase # カタカナ→ひらがな＋小文字化
  
      @groups = Group.where("LOWER(name) LIKE ?", "%#{@query.downcase}%")
               .or(Group.where("LOWER(name) LIKE ?", "%#{normalized_query}%"))
               .where(privacy: ["public_visibility", "restricted_visibility"]) # プライバシー設定を考慮
    else
      @groups = @user.groups
    end
  end

  def show
    @group = Group.find(params[:id])
    @user = User.find(params[:user_id]) # ユーザー情報を取得
    @membership = current_user.memberships.find_by(group: @group)
    
    session[:return_to] = request.original_url # どこから来たか保存
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
    @user = User.find(params[:user_id]) # ユーザー情報を取得
  
    # 承認制グループかチェック
    if @group.privacy != "restricted_visibility"
      redirect_to user_group_path(@user, @group), alert: "このグループは参加リクエスト不要です。"
      return
    end
  
    # すでにメンバーかチェック
    if @group.users.exists?(id: @user.id)
      redirect_to user_group_path(@user, @group), alert: "すでにメンバーです！"
      return
    end
  
    # 参加リクエストを "pending" 状態で保存
    @group.memberships.create!(user: @user, role: "pending")
  
    redirect_to user_group_path(@user, @group), notice: "参加リクエストを送信しました！"
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
  
  private

  def group_params
    params.require(:group).permit(:name, :category, :privacy, :join_policy)
  end

end