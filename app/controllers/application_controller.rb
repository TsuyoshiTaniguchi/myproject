class ApplicationController < ActionController::Base
  before_action :authenticate_user!, except: [:top]
  before_action :authenticate_user!, unless: -> { admin_signed_in? }
  before_action :configure_permitted_parameters, if: :devise_controller?

  include Devise::Controllers::Helpers

  helper_method :admin_signed_in?

def admin_signed_in?
  !current_admin.nil?
end


  def after_sign_in_path_for(resource)
    case resource
    when Admin
      admin_root_path
    when User
      root_path
    else
      root_path
    end
  end


  def after_sign_out_path_for(resource)
    about_path
  end

  def authenticate_admin!
    redirect_to new_admin_session_path unless admin_signed_in?
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
  end

end
