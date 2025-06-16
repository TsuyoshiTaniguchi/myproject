# app/helpers/guest_helper.rb
module GuestHelper
  # true なら “ゲストなので書き込み系 UI を隠す”
  def guest_blocked?
    current_user&.guest?
  end
end