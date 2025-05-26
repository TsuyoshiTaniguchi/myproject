class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable


  # スコープ：アクティブユーザーのみ取得
  scope :active, -> { where(status: "active") }

  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :memberships
  has_many :groups, through: :memberships
  has_many :likes
  has_many :liked_posts, through: :likes, source: :post



  has_one_attached :profile_image # プロフィール画像の添付機能を追加

  enum status: { active: 0, withdrawn: 1 }

  # ActiveStorageを使用する場合（プロフィール画像）
  has_one_attached :profile_image

  validates :email, presence: true, uniqueness: true
  validates :personal_statement, length: { maximum: 500 } # プロフィールの制限

  # validates :location, presence: true ← 拡張機能時に追加

  before_validation :set_default_status, on: :create

  # ユーザー認証の有効/無効チェック
  def active_for_authentication?
    super && status == "active"
  end

  def display_status
    status == "active" ? "アクティブ" : "退会済み"
  end
  

  # ユーザーの退会処理
  def withdraw!
    update(status: "withdrawn")
    reload # データを即反映
  end

  def like_for(post)
    likes.find_by(post: post) || nil # 明示的に `nil` を返すことでエラーを防げる
  end


 private

  def set_default_status
    self.status ||= "active"
  end
end






