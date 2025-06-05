class Admin::UsersController < ApplicationController
  before_action :authenticate_admin!
  layout 'admin'


  def index
    @users_by_status = User.all.group_by(&:status)
    @users = User.where.not(status: nil)
  
    # フィルター処理
    if params[:filter] == "active"
      @users = @users.where(status: "active")
    elsif params[:filter] == "reported"
      @users = @users.where(reported: true)
    end

      # ソート処理
    case params[:sort]
    when "newest"
      @users = @users.order(created_at: :desc)
    when "oldest"
      @users = @users.order(created_at: :asc)
    end

  end

  def show
    @user = User.find(params[:id])
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    Rails.logger.debug "更新前ステータス: #{@user.status}"
    
    if params[:cancel]
      return redirect_to admin_user_path(@user) 
    end
  
    if @user.update(user_params)
      Rails.logger.debug "更新後ステータス: #{@user.reload.status}"
      redirect_to admin_user_path(@user), notice: "ユーザー情報を更新しました"
    else
      flash[:alert] = @user.errors.full_messages.join(", ")
      render :edit
    end
  end


  def destroy
    @user = User.find(params[:id])

    # 関連するデータを削除
    @user.posts.destroy_all
    @user.comments.destroy_all
    @user.likes.destroy_all
    @user.notifications.destroy_all

    # ActiveStorageの添付ファイルも削除
    @user.profile_image.purge if @user.profile_image.attached?
    @user.portfolio_files.purge if @user.portfolio_files.attached?

    # ユーザー削除
    @user.destroy

    redirect_to admin_users_path, notice: "ユーザーを削除しました"
  end

  def toggle_status
    user = User.find(params[:id])
    if user.active?
      user.update(status: :withdrawn)
      flash[:notice] = "#{user.name} のアカウントを退会状態にしました"
    else
      user.update(status: :active)
      flash[:notice] = "#{user.name} のアカウントを有効化しました"
    end
    redirect_back(fallback_location: admin_users_path)
  end

  def followers
    @user = User.find(params[:id])
    @followers = @user.followers  # フォロワー一覧を取得
    
    respond_to do |format|
      format.html # HTMLを返す
      format.json { render json: @followers } # JSONレスポンスも許可
    end
  end

  def following
    @user = User.find(params[:id])
    @following_users = @user.following   # フォローしているユーザー一覧を取得
  
    respond_to do |format|
      format.html # ビューを表示
      format.json { render json: @following_users } # JSONレスポンスも許可
    end
  end

  def search
    @query = params[:query]
    @users = User.where("name LIKE ?", "%#{@query}%")
    render :index
  end

  def unreport
    @user = User.find(params[:id])
    @user.update(reported: false)
    redirect_to admin_users_path, notice: "#{@user.name} の通報を解除しました。"
  end
  
  private

  def user_params
    params.require(:user).permit(:name, :email, :status, :role)
  end

end