class Post < ApplicationRecord

  belongs_to :user
  belongs_to :group, optional: true # グループ内投稿の関係を追加

  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :notifications, as: :source, dependent: :destroy # ポリモーフィック関連の通知

  # スコープ（アクティブユーザーのみの投稿）
  scope :active_users_posts, -> { joins(:user).where(users: { status: "active" }) }


  validates :title, presence: true
  validates :content, presence: true, length: { minimum: 10 }
  validates :group_id, presence: true, allow_nil: true # 投稿が必ずグループに属するようにする

   # 投稿のステータス管理
   enum status: { normal: 0, reported: 1 }  # `status` カラムで通報を管理
  
   def reported?
     status == "reported"
   end
 
end