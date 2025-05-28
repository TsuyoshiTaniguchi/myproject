class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable


  # スコープ：アクティブユーザーのみ取得
  scope :active, -> { where(status: "active") }

  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :memberships
  has_many :groups, through: :memberships
  has_many :likes, dependent: :destroy
  has_many :liked_posts, through: :likes, source: :post
  has_many :notifications, dependent: :destroy

  has_many_attached :portfolio_files

  has_one_attached :profile_image # プロフィール画像の添付機能を追加


  enum status: { active: 0, withdrawn: 1 }


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

  def get_profile_image(width, height)
    unless profile_image.attached?
      file_path = Rails.root.join('app/assets/images/sample-author1.jpg')
      profile_image.attach(io: File.open(file_path), filename: 'default-image.jpg', content_type: 'image/jpeg')
    end
    "no_image.jpg"
  end

  def admin?
    role.to_s == "admin"
  end

  GUEST_USER_EMAIL = "guest@example.com"

  def self.guest
    find_or_create_by!(email: GUEST_USER_EMAIL) do |user|
      user.password = SecureRandom.urlsafe_base64
      user.name = "guestuser"
    end
  end

  def guest_user?
    email == GUEST_USER_EMAIL
  end

  def guest?
    role == "guest"
  end


 private

  def set_default_status
    self.status ||= "active"
  end
end






