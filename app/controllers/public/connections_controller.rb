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
    current_user.disconnect(@user)

    respond_to do |format|
      format.html { redirect_back fallback_location: user_path(@user),
                                  notice: "フォロー解除しました" }
      format.js   # destroy.js.erb を置けば Ajax でもOK
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