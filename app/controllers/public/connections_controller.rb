class Public::ConnectionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: %i[create destroy]

  # ---------------- フォロー ----------------
  # POST /users/:id/follow
  def create
    current_user.connect(@user)

    respond_to do |format|
      format.html { redirect_back fallback_location: user_path(@user),
                                  notice: "#{@user.name}さんをフォローしました！" }
      format.js   # create.js.erb を置けば Ajax でもOK
    end
  end

  # -------------- フォロー解除 ---------------
  # DELETE /users/:id/unfollow
  def destroy
    # set_user で params[:id] を @user にセット済み
    # ① 自分が相手をフォローしている場合
    conn = current_user.connections.find_by(followed_id: @user.id)
    # ② それ以外に、相手が自分をフォローしている場合
    conn ||= Connection.find_by(follower_id: @user.id, followed_id: current_user.id)
  
    conn&.destroy
  
    respond_to do |format|
      format.js   # destroy.js.erb で行ごと削除
      format.html { redirect_back fallback_location: user_path(@user),
                                  notice: "フォローを解除しました" }
    end
  end
  


  def following
    @user  = User.find(params[:id])
    @users = @user.following
  end

  def followers
    @user  = User.find(params[:id])
    @users = @user.followers
  end

  private

  # member ルートなので params[:id] に相手ユーザーIDが入る
  def set_user
    @user = User.find(params[:id])
  end

end