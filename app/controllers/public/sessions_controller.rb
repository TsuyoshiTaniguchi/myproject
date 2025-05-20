# frozen_string_literal: true

class Public::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  # ユーザーcreate前にreject_userを呼び出す
  before_action :reject_user, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  # def create
  #   super
  # end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  protected

  def after_sign_in_path_for(resource) #会員のログイン後の遷移先
    root_path
  end

  def after_sign_out_path_for(resource) #会員のログアウト後の遷移先
    root_path
  end

  # 退会済みのユーザーがログインできないようにする（退会処理とは別）
  def reject_user
    @user = User.find_by(email: params[:user][:email])
    if @user
      # もしパスワードが正しい場合で、なおかつ status が false (退会済み) の場合にリダイレクト
      if @user.valid_password?(params[:user][:password]) && @user.status == false
        flash[:alert] = "退会済みです。再度ご登録をしてご利用ください"
        redirect_to new_user_registration_path and return
      end
    else
      flash[:alert] = "該当するユーザーが見つかりません"
      redirect_to new_user_session_path and return
    end
  end
  # If you have extra params to permit, append them to the sanitizer.



  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end

end
