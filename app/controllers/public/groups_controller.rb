class Public::GroupsController < ApplicationController
  before_action :authenticate_user!
  before_action :restrict_guest_access, only: [:create]

  def index
    # `params[:user_id]` が存在するかチェックし、ユーザーを取得
    if params[:user_id].present?
      @user = User.find(params[:user_id])
      @groups = Group.where(id: @user.memberships.pluck(:group_id)) #　参加しているグループを取得
    else
      @groups = Group.all # `user_id` がない場合は全グループを表示
    end
  
    # 検索キーワードの取得
    @query = params[:query]
  
    if @query.present?
      # 検索を柔軟にするため、カタカナをひらがなへ変換し、小文字化
      normalized_query = @query.tr('ァ-ン', 'ぁ-ん').downcase
  
      # グループ名の検索（大文字小文字を区別せずマッチ）
      @groups = @groups.where("LOWER(name) LIKE ?", "%#{@query.downcase}%")
                       .or(@groups.where("LOWER(name) LIKE ?", "%#{normalized_query}%"))
                       .where(privacy: ["public_visibility", "restricted_visibility"]) # 非公開グループを除外
    else
      @groups = @groups.includes(:memberships) #  関連データを読み込み、N+1問題を回避
    end
  end

  def show
    @group = Group.find(params[:id])
    @user = @group.owner # グループオーナーの情報を取得
    @membership = current_user.memberships.find_by(group: @group)
  
    # 最近の投稿と新規メンバーを取得
    @recent_posts = @group.posts.order(created_at: :desc).limit(5)

    #  管理者を除外
    @new_members = @group.users.where.not(role: "admin").order(created_at: :desc).limit(3) 
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
  
      redirect_to group_path(@group), notice: "グループを作成しました！"
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
      redirect_to group_path(@group), notice: "グループ情報を更新しました！"
    else
      render :edit
    end
  end

  def request_join
    @group = Group.find(params[:id])
    @user = current_user
  
    if @user.guest?
      return redirect_to group_path(@group), alert: "ゲストユーザーはグループに参加できません。"
    end
  
    # すでにメンバーかチェック
    membership = @group.memberships.find_by(user: @user)
  
    if membership&.role == "member"
      return redirect_to group_path(@group), alert: "すでにメンバーとして参加済みです！"
    elsif membership&.role == "pending"
      return redirect_to group_path(@group), alert: "すでに参加リクエストを送信済みです！"
    end
  
    # `public_visibility` の場合は即参加
    if @group.privacy == "public_visibility"
      @group.memberships.create!(user: @user, role: "member")
      return redirect_to group_path(@group), notice: "グループに参加しました！"
    end
  
    # `admin_approval` の場合は `pending` に設定し、承認待ち！
    if @group.join_policy == "admin_approval"
      @group.memberships.create!(user: @user, role: "pending")
      return redirect_to group_path(@group), notice: "参加リクエストを送信しました。管理者の承認を待っています。"
    end
  
    # `restricted_visibility` の場合もリクエストを送信
    @group.memberships.create!(user: @user, role: "pending")
    redirect_to group_path(@group), notice: "参加リクエストを送信しました！"
  end
  
  def leave
    @group = Group.find(params[:id])
    @membership = current_user.memberships.find_by(group: @group)
  
    if @membership
      @membership.destroy
      return redirect_to groups_path, notice: "グループを退会しました"
    else
      return redirect_to group_path(@group), alert: "グループに所属していません"
    end
  end

  def destroy
    @group = Group.find(params[:id])
  
    if @group.destroy
      return redirect_to groups_path, notice: "グループを削除しました"
    else
      return redirect_to group_path(@group), alert: "グループを削除できませんでした"
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

  def report
    @group = Group.find_by(id: params[:id])
    
    # グループが存在しない場合
    unless @group
      redirect_to groups_path, alert: "指定されたグループが見つかりませんでした"
      return
    end
  
    # すでに通報済みなら処理をスキップ
    if @group.reported?
      redirect_to group_path(@group), alert: "このグループはすでに通報済みです"
      return
    end
  
    #  管理者の存在を確認
    admin = Admin.first
    unless admin
      redirect_to group_path(@group), alert: "管理者が見つかりません"
      return
    end
  
    #  通報処理の実行
    if @group.update(reported: true)
      Notification.create(
        user_id: admin.id,  #  通報の受信者（管理者）
        source_id: current_user.id,  #  通報者（ユーザー）
        source_type: "User",  #  通報者のタイプ
        notification_type: "group_reported"
      )
      redirect_to group_path(@group), notice: "グループを通報しました"
    else
      redirect_to group_path(@group), alert: "通報処理に失敗しました"
    end
  end

  private

  def already_reported?(group)
    group.reported? # 通報済みかチェックをメソッド化
  end

  def group_params
    params.require(:group).permit(:name, :privacy, :join_policy, :location, :description, :group_image, :category)
  end
end