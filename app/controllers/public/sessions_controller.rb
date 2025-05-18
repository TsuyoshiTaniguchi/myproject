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

  # 退会済みのユーザーがログインできないようにする（退会処理とは別）
  def reject_user
    @user = User.find_by(email: params[:user][:email])
    # 存在しているかどうか分岐
    if @user
      # 退会フラグが退会済みか有効化判断
      if @user.valid_password?(params[:user][:password]) && (@user.status == true)
        flash[:notice] = "退会済みです。再度ご登録をしてご利用ください"
        redirect_to new_user_registration_path
      end
    else
      # そもそも存在していなかった場合
      flash[:notice] = "該当するユーザーが見つかりません"
    end
  end

  # If you have extra params to permit, append them to the sanitizer.

  def after_sign_in_path_for(resource) #会員のログイン後の遷移先
    root_path
  end

  def after_sign_out_path_for(resource) #会員のログアウト後の遷移先
    root_path
  end

  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end

  private
# アクティブであるかを判断するメソッド
  def customer_state
  # 【処理内容1】 入力されたemailからアカウントを1件取得
  user = User.find_by(email: params[:user][:email])
  # 処理内容2
  # customer.nil?ではないことに注意, ここではcustomerが存在する場合に後続の処理を実行したいため
      if user
    # 処理内容3
    # unlessではないことに注意, ここではパスワードが正しい場合に後続の処理を実行したいため
      if user.valid_password?(params[:user][:password])
      #処理内容４
        flash[:notice] = "退会済みです。再度ご登録をしてご利用ください"
        redirect_to new_user_registration_path
      else
        flash[:notice] = "項目を入力してください"
      end
      else
      flash[:notice] = "該当するユーザーが見つかりません"
      end
  end
end
