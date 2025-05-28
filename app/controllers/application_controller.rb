class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :restrict_guest_access, only: [:edit, :update, :destroy]


    # ログアウト後のリダイレクト先を指定
    def after_sign_out_path_for(resource_or_scope)
      root_path
    end
  

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :status]) # status も含めてデフォルト値を設定する場合
  end

  private


  private

  def restrict_guest_access
    return unless current_user.present?  # ✅ `current_user` が `nil` でないことを確認！
    
    if current_user.guest?
      redirect_to root_path, alert: "ゲストユーザーはこの操作を実行できません"
    end
  end
  

end

