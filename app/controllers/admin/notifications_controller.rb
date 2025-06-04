class Admin::NotificationsController < ApplicationController
  before_action :authenticate_admin!

  def index
    # "admin_alert" を使うのではなく、既に定義されている"group_reported"を表示する例
    @admin_notifications = Notification.where(notification_type: "group_reported").order(created_at: :desc)
  end

end