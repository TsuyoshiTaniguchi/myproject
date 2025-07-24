class Public::HomesController < ApplicationController
  before_action :authenticate_customer!, except: [:top, :about]
  
  def top
    if user_signed_in? && current_user.is_a?(User) # ✅ `Admin` の場合は処理しない
      @posts = Post.where(user_id: current_user.following.pluck(:id)) # フォローしているユーザーの投稿を取得！
    else
      @posts = Post.order("created_at DESC").limit(10) # ✅ `Admin` の場合は適当な投稿を表示
    end
  end



  def about
  end
  
end