class Admin::ApplicationController < ApplicationController

  before_action :authenticate_admin!
  # 管理者専用のレイアウトがある場合は指定
  layout 'admin'
  
end