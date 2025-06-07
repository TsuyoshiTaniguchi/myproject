class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
  :recoverable, :rememberable, :validatable

  # スコープ：アクティブユーザーのみ取得
  scope :active, -> { where(status: statuses[:active]) }

  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :memberships
  has_many :groups, through: :memberships
  has_many :joined_groups, -> { where(memberships: { role: ["member", "owner"] }) }, through: :memberships, source: :group
  has_many :likes, as: :likeable, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :daily_reports
  has_many :skill_tags, through: :daily_reports



  #  フォロー関係の関連付け
  has_many :connections, foreign_key: :follower_id, dependent: :destroy
  has_many :following, through: :connections, source: :followed

  has_many :reverse_connections, class_name: "Connection", foreign_key: :followed_id, dependent: :destroy
  has_many :followers, through: :reverse_connections, source: :follower

  has_many_attached :portfolio_files
  has_one_attached :profile_image

  #  フォロー機能（connect/disconnect）
  def connect(user)
    connections.create(followed_id: user.id) unless following.include?(user)
  end

  def disconnect(user)
    connection = connections.find_by(followed_id: user.id)
    connection&.destroy
  end

  enum status: { active: 0, withdrawn: 1 }

  validates :email, presence: true, uniqueness: true
  validates :personal_statement, length: { maximum: 500 }
  # reported フラグ
  validates :reported, inclusion: { in: [true, false] }


  before_validation :set_default_status, on: :create

  #  認証チェック
  def active_for_authentication?
    super && status == "active"
  end

  def display_status
    status == "active" ? "アクティブ" : "退会済み"
  end

  def withdraw!
    update(status: "withdrawn")
    reload
  end

  def get_profile_image(width, height)
    if profile_image.attached?
      profile_image.variant(resize_to_fill: [width, height]).processed
    else
      "no_image.jpg"
    end
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

  # メンバー判定メソッド
  def member_of?(group)
    memberships.exists?(group_id: group.id)
  end  
  

  private

  def set_default_status
    self.status ||= "active"
  end

end







