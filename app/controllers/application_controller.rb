class ApplicationController < ActionController::Base

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_unread_notifications_count
  before_action :set_cache_buster

  # ゲスト書き込みブロック（全コントローラ共通
  before_action :reject_guest_write, if: -> { current_user&.guest? }

  # Devise リダイレクトなど 
  def after_sign_in_path_for(resource)
    resource.is_a?(Admin) ? admin_dashboard_path : users_mypage_path
  end

  def after_sign_out_path_for(_scope)
    root_path
  end

  # 管理者ログイン中は current_user を nil 扱い
  def current_user
    admin_signed_in? ? nil : super
  end


  SAFE_HTTP_METHODS = %w[GET HEAD OPTIONS].freeze

  # ゲストにも許可したい “例外” アクションを列挙
  # controller_name(シンボル) => [ :action, … ]
  GUEST_WHITELIST = {
    sessions:  %i[destroy],      # 例：ログアウト
    passwords: %i[new create]    # 例：パスワード再設定
  }.freeze

  def reject_guest_write
    # 安全メソッドなら通す
    return if SAFE_HTTP_METHODS.include?(request.method)

    # ホワイトリストなら通す
    ctrl = params[:controller].split('/').last.to_sym
    act  = params[:action].to_sym
    return if GUEST_WHITELIST[ctrl]&.include?(act)

    # それ以外はブロック
    redirect_back fallback_location: root_path,
                  alert: 'ゲストユーザーはこの操作を実行できません'
  end



  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[name status])
  end

  private


  def set_unread_notifications_count
    if admin_signed_in?
      # 管理者ログイン中は、User テーブルにある管理者レコード（例: admin@example.com）から通知を取得する
      admin_user = User.find_by(email: 'admin@example.com')
      @unread_notifications_count = admin_user ? admin_user.notifications.unread.count : 0
    elsif current_user.present?
      @unread_notifications_count = current_user.notifications.unread.count
    else
      @unread_notifications_count = 0
    end
  end

  def set_cache_buster
    response.headers['Cache-Control'] = 'no-store, no-cache, must-revalidate, max-age=0'
    response.headers['Pragma']        = 'no-cache'
    response.headers['Expires']       = 'Fri, 01 Jan 1990 00:00:00 GMT'
  end
end