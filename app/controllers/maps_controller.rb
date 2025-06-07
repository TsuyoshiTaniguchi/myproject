class MapsController < ApplicationController
  class MapsController < ApplicationController
    before_action :check_admin, only: [:edit, :update] # 管理者チェック
    
    def show
      @location = { lat: 35.6764225, lng: 139.650027 } # 東京の座標
    end
  
    def edit
      # 管理者のみ編集画面にアクセスできる
    end
  
    def update
      if current_user.admin?
        # 管理者のみ地図データを更新可能
      else
        redirect_to maps_path, alert: "権限がありません。"
      end
    end
  
    private
    def check_admin
      redirect_to root_path unless current_user.admin?
    end
  end
