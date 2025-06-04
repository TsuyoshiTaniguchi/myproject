class Admin < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable,
         :rememberable, :validatable, :confirmable
        
  has_many :notifications, dependent: :destroy #  通知を関連付け
  has_many :admin_logs, dependent: :destroy


  validates :email, presence: true, uniqueness: true

  

  # 管理者専用のアカウント作成を制限する（新規登録禁止）
  def self.create_admin_account(email, password)
    create!(email: email, password: password, confirmed_at: Time.current)
  end
end