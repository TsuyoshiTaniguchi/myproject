class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @notifications = current_user.notifications.select(:id, :user_id, :notification_type, :source_id, :source_type, :read, :created_at).order(created_at: :desc).limit(5)
  end


  def update
    notification = current_user.notifications.find_by(id: params[:id])

    if notification
      notification.update(read: true)
      redirect_to notification_redirect_path(notification)
    else
      redirect_to notifications_path, alert: "通知が見つかりません"
    end
  end

  def show
    @notification = current_user.notifications.find_by(id: params[:id])
  
    if @notification
      @notification.update(read: true) # ✅ 既読にする
      redirect_to notification_redirect_path(@notification) # ✅ 通知の関連ページへ移動
    else
      redirect_to notifications_path, alert: "通知が見つかりません"
    end
  end

  private

  def notification_redirect_path(notification)
    case notification.source_type
    when "Comment"
      post_path(notification.source.post)
    else
      user_path(notification.source.user || notifications_path)
    end
  end
end 