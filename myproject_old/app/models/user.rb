# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # スコープ：アクティブユーザーのみ取得
  scope :active, -> { where(status: statuses[:active]) }

  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :groups, through: :memberships
  has_many :joined_groups, -> { where(memberships: { role: ["member", "owner"] }) },
           through: :memberships, source: :group
  has_many :owned_groups, class_name: "Group", foreign_key: "owner_id"

  has_many :likes, as: :likeable, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :daily_reports, class_name: "::DailyReport"

  # フォロー関係の関連付け
  has_many :connections, foreign_key: :follower_id, dependent: :destroy
  has_many :following, through: :connections, source: :followed

  has_many :reverse_connections, class_name: "Connection",
           foreign_key: :followed_id, dependent: :destroy
  has_many :followers, through: :reverse_connections, source: :follower

  has_many_attached :portfolio_files
  has_one_attached :profile_image

  # フォロー機能（connect/disconnect）
  def connect(user)
    connections.create(followed_id: user.id) unless following.include?(user)
  end

  def disconnect(user)
    connection = connections.find_by(followed_id: user.id)
    connection&.destroy
  end

  enum status: { active: 0, withdrawn: 1 }

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :personal_statement, length: { maximum: 500 }
  validates :reported, inclusion: { in: [true, false] }
  validates :portfolio_url,
  format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
            message: "は有効なURL形式で入力してください" },
  allow_blank: true
  # 添付ファイルのバリデーションを登録
  validate :validate_portfolio_files

  before_validation :set_default_status, on: :create

  # 既存列 role:string default:"user" をそのまま使う
  enum role: { guest: "guest", user: "user", admin: "admin" }

  # 引数のユーザーをすでにフォローしているか？
  def following?(other_user)
    following.exists?(other_user.id)
  end

  # 認証チェック
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

  def validate_portfolio_files
    return unless portfolio_files.attached?

    # 件数チェック
    if portfolio_files.count > 5
      errors.add(:portfolio_files, "は最大5つまでアップロードできます")
    end

    portfolio_files.each do |file|
      # MIMEタイプチェック
      unless file.content_type.in?(%w[image/png image/jpeg application/pdf])
        errors.add(:portfolio_files, "はPNG・JPEG・PDFのみアップロードできます")
      end

      # サイズチェック
      if file.byte_size > 5.megabytes
        errors.add(:portfolio_files, "は5MB以内のファイルにしてください")
      end
    end
  end


  def set_default_status
    self.status ||= "active"
  end
  
end