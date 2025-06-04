class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @notifications = current_user.notifications
                      .select(:id, :user_id, :notification_type, :source_id, :source_type, :read, :created_at)
                      .order(created_at: :desc)
                      .limit(5)
  end

  def update
    notification = current_user.notifications.find_by(id: params[:id])
    if notification
      # ここでは update_column を使って、即座に read 属性を変更する（コールバック等をバイパス）
      notification.update_column(:read, true)
      
      begin
        redirect_path = notification_redirect_path(notification)
      rescue => e
        Rails.logger.warn("Error computing redirect path for Notification #{notification.id}: #{e.message}")
        redirect_path = root_path
      end
      redirect_to redirect_path
    else
      redirect_to notifications_path, alert: "通知が見つかりません"
    end
  end

  def show
    @notification = current_user.notifications.find_by(id: params[:id])
    if @notification
      @notification.update(read: true)  # 既読にする
      redirect_to notification_redirect_path(@notification)  # 通知の関連ページへ移動
    else
      redirect_to notifications_path, alert: "通知が見つかりません"
    end
  end

  private

  # 通知の転送先を安全に決定する
  def notification_redirect_path(notification)
    source = notification.source
    return root_path unless source.present?
  
    case notification.source_type
    when "Comment"
      if source.respond_to?(:post) && source.post.present?
        post_path(source.post)
      else
        Rails.logger.warn "Notification #{notification.id} (Comment) has invalid post source. Redirecting to root_path."
        root_path
      end
    when "Group"
      if source.respond_to?(:owner) && source.owner.present?
        user_path(source.owner)
      else
        Rails.logger.warn "Notification #{notification.id} (Group) has invalid owner. Redirecting to root_path."
        root_path
      end
    else
      if source.respond_to?(:user) && source.user.present?
        user_path(source.user)
      else
        Rails.logger.warn "Notification #{notification.id} has unrecognized source. Redirecting to root_path."
        root_path
      end
    end
  end
end