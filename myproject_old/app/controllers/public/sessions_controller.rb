# frozen_string_literal: true

class Public::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  # ユーザーcreate前にreject_userを呼び出す
  before_action :reject_user, only: [:create]

  skip_before_action :verify_signed_out_user, only: :destroy #  フィルターをスキップ

  def destroy
    if admin_signed_in?
      sign_out current_admin #  `Admin` のログアウト処理
      redirect_to new_admin_session_path, notice: "管理者としてログアウトしました"
    elsif current_user&.guest?
      reset_session  #  ゲストユーザーのセッションをクリア
      cookies.delete(:guest_user_id)  # クッキーを削除
      sign_out current_user  #  ログアウト処理を実行
      redirect_to about_path, notice: "ゲスト利用ありがとうございました！ もし気に入っていただけたら、ぜひ新規登録してください！"
    else
      sign_out current_user if current_user.present? # `current_user` が存在する場合のみログアウト！
      redirect_to root_path, notice: "ログアウトしました！"
    end
  end


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
  
  def guest_login
    user = User.guest
    sign_in user
    redirect_to root_path, notice: "ゲストログインしました"
  end



  protected

  def after_sign_in_path_for(resource) #会員のログイン後の遷移先
    users_mypage_path
  end

  def after_sign_out_path_for(resource) #会員のログアウト後の遷移先
    root_path
  end

  # 退会済みのユーザーがログインできないようにする（退会処理とは別）
  def reject_user
    return if params[:controller] == "admin/sessions" #  管理者ログイン時は処理をスキップ
  
    @user = User.find_by(email: params[:user][:email])
    if @user && @user.valid_password?(params[:user][:password])
      if @user.status == false
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

  private

  def self.guest
    find_or_create_by!(email: "guest@example.com") do |user|
      user.password = SecureRandom.urlsafe_base64
      user.name = "ゲストユーザー"
      user.role = "guest" # これがないとゲスト判定ができない
    end
  end


end
