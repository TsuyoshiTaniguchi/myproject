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
      # update_column を使うとコールバックをスキップして即時更新されます
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
      redirect_to notification_redirect_path(@notification)  # 通知に関連するページへ移動
    else
      redirect_to notifications_path, alert: "通知が見つかりません"
    end
  end

  # すべて既読にするアクション（ルートヘルパー mark_all_read_notifications_path を使えるようにする）
  def mark_all_read
    current_user.notifications.where(read: false).update_all(read: true)
    redirect_to notifications_path, notice: "すべての通知が既読になりました。"
  end

  private

  # 安全に通知の転送先を決定するメソッド
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