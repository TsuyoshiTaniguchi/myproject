# app/helpers/guest_helper.rb
module GuestHelper
 # → email が guest@example.com の時だけ true を返す
  def guest_blocked?
    current_user&.guest_user?
  end

end