class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable



  # スコープ：アクティブユーザーのみ取得
  scope :active, -> { where(status: "active") }




  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :user_groups, dependent: :destroy
  has_many :groups, through: :user_groups

  # ActiveStorageを使用する場合（プロフィール画像）
  has_one_attached :profile_image

  validates :email, presence: true, uniqueness: true
  validates :personal_statement, length: { maximum: 500 } # プロフィールの制限
  validates :location, presence: true

  # ユーザー認証の有効/無効チェック
  def active_for_authentication?
    super && status == true
  end
  
  
  

  # ユーザーの退会処理
  def withdraw!
    update(status: "withdrawn")
  end
end