class Connection < ApplicationRecord
  # アソシエーション
  belongs_to :follower, class_name: "User"
  belongs_to :followed, class_name: "User"

  # バリデーション
  validates :follower_id, presence: true
  validates :followed_id, presence: true
  validates :follower_id, uniqueness: { scope: :followed_id } # 同じユーザーを複数回フォローできないように

  # スコープ（特定ユーザーのフォロワー / フォロー一覧）
  scope :followers_of, ->(user) { where(followed_id: user.id) }
  scope :following_by, ->(user) { where(follower_id: user.id) }
end