class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :restrict_guest_access, only: [:edit, :update]
  before_action :set_unread_notifications_count
  before_action :set_cache_buster


  # ユーザーと管理者でログイン後のリダイレクト先を分ける
  def after_sign_in_path_for(resource)
    if resource.is_a?(Admin)
      admin_dashboard_path # 管理者は管理画面へ
    else
      users_mypage_path # 一般ユーザーはマイページへ
    end
  end
  
  
  
  # ログアウト後のリダイレクト先を指定
  def after_sign_out_path_for(resource_or_scope)
    root_path
  end

  def current_user
    if admin_signed_in?
      nil #  管理者の場合は `current_user` を返さない
    else
      super #  通常の `current_user` を返す
    end
  end



  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :status]) # status も含めてデフォルト値を設定する場合
  end

  private


  def restrict_guest_access
    return unless current_user # `nil` チェックを追加
    
    return if params[:action] == "destroy" # ログアウト時は制限をスキップ
  
    if current_user.guest?
      redirect_to root_path, alert: "ゲストユーザーはこの操作を実行できません"
    end
  end

  def set_unread_notifications_count
    if current_user.is_a?(User) # `Admin` の場合は処理しない
      @unread_notifications_count = current_user.notifications.where(read: false).count
    else
      @unread_notifications_count = 0 # `Admin` の場合は通知を持たない
    end
  end

  def set_cache_buster
    response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end


end

