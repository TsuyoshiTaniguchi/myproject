class Post < ApplicationRecord
  # アソシエーション
  belongs_to :user
  belongs_to :group # グループ内投稿の関係を追加

  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :notifications, as: :source, dependent: :destroy # ポリモーフィック関連の通知

  # スコープ（アクティブユーザーのみの投稿）
  scope :active_users_posts, -> { joins(:user).where(users: { status: "active" }) }

  # バリデーション
  validates :title, presence: true
  validates :content, presence: true, length: { minimum: 10 }
  validates :group_id, presence: true # 投稿が必ずグループに属するようにする
end