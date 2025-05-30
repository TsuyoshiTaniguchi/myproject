class Admin::NotificationsController < ApplicationController
  before_action :authenticate_admin!

  def index
    @admin_notifications = Notification.where(notification_type: "admin_alert").order(created_at: :desc)
  end
end