class Admin::NotificationsController < ApplicationController
  before_action :authenticate_admin!
  layout 'admin'

  def index
    # Userテーブル側の管理者レコード（admin@example.com）から通知を取得
    admin_user = User.find_by(email: 'admin@example.com')
    # 見つからなかった場合でも必ず空配列をセットする
    @admin_notifications = admin_user ? admin_user.notifications.unread.order(created_at: :desc) : []
  end

  # 個別通知を既読に更新
  def mark_read
    @notification = Notification.find(params[:id])
    @notification.update(read: true)
    redirect_to admin_notifications_path, notice: "通知を既読にしました"
  end

  # 全通知を一括で既読に更新
  def mark_all_read
    # current_admin ではなく、User 側の管理者レコードを対象にする
    admin_user = User.find_by(email: 'admin@example.com')
    if admin_user
      Notification.where(user: admin_user, read: false).update_all(read: true)
      notice = "全ての通知を既読にしました"
    else
      notice = "管理者の通知が見つかりません"
    end
    redirect_to admin_notifications_path, notice: notice
  end
  
end
