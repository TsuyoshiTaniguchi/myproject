class Public::UsersController < ApplicationController

  def withdraw
    current_user.withdraw!
    reset_session
    redirect_to root_path, notice: "退会処理が完了しました"
  end

end
