class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?

    # ログアウト後のリダイレクト先を指定
    def after_sign_out_path_for(resource_or_scope)
      root_path
    end
  

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :status]) # status も含めてデフォルト値を設定する場合
  end

end

