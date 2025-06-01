class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :restrict_guest_access, only: [:edit, :update]
  before_action :set_unread_notifications_count

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


  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :status]) # status も含めてデフォルト値を設定する場合
  end

  private


  def restrict_guest_access
    return unless current_user.present?  # `current_user` が `nil` でないことを確認！
    
    return if params[:action] == "destroy"  # ログアウト時は制限をスキップ
  
    if current_user.guest?
      redirect_to root_path, alert: "ゲストユーザーはこの操作を実行できません"
    end
  end

  def set_unread_notifications_count
    @unread_notifications_count ||= current_user.notifications.where(read: false).count if user_signed_in?
  end

  

end

