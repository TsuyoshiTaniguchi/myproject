class Public::HomesController < ApplicationController
  before_action :authenticate_customer!, except: [:top, :about]
  
  def top
    if user_signed_in?
      @posts = Post.where(user_id: current_user.following.pluck(:id)) # フォローしているユーザーの投稿を取得！
    else
      @posts = [] # ログインしていない場合は空の配列をセット！（エラー回避）
    end
  end


  def about
  end
  
end