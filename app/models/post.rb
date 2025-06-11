class Post < ApplicationRecord

  belongs_to :user
  belongs_to :group, optional: true # グループ内投稿の関係を追加

  has_many :comments, dependent: :destroy
  has_many :likes, as: :likeable, dependent: :destroy
  has_many :notifications, as: :source, dependent: :destroy # ポリモーフィック関連の通知


  has_many_attached :images # 複数画像アップロードを可能に！

  acts_as_taggable_on :tags



  # スコープ（アクティブユーザーのみの投稿）
  scope :active_users_posts, -> { joins(:user).where(users: { status: "active" }) }

  # 投稿のステータス管理
  enum status: { normal: 0, reported: 1 }  # `status` カラムで通報を管理
  
  validates :title, presence: true
  validates :content, presence: true, length: { minimum: 10 }
  validates :group_id, presence: true, allow_nil: true # 投稿が必ずグループに属するようにする
  validates :code_snippet, length: { maximum: 1000 }, allow_blank: true # コードの長さを制限


   # シンプルに restricted_visibility のみの場合（private_visibility が必要なければ）
   scope :visible_to, ->(user) {
    left_outer_joins(:group).where(
      "posts.group_id IS NULL OR 
       groups.privacy = :public_visibility OR 
       (groups.privacy = :restricted_visibility 
         AND EXISTS (
           SELECT 1 FROM memberships 
           WHERE memberships.group_id = posts.group_id 
           AND memberships.user_id = :user_id
         )
       )",
      public_visibility: Group.privacies[:public_visibility],
      restricted_visibility: Group.privacies[:restricted_visibility],
      user_id: user.id
    )
  }

  def reported?
    status == "reported"
  end

  def liked_by?(user)
    return false unless user.present? # `nil` の場合は明示的に `false` を返す
    likes.where(user_id: user.id).exists?
  end
end