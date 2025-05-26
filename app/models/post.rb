class Post < ApplicationRecord

  belongs_to :user
  belongs_to :group, optional: true # グループ内投稿の関係を追加

  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :notifications, as: :source, dependent: :destroy # ポリモーフィック関連の通知

  has_one_attached :image # 画像アップロード機能を追加


  # スコープ（アクティブユーザーのみの投稿）
  scope :active_users_posts, -> { joins(:user).where(users: { status: "active" }) }

  # 投稿のステータス管理
  enum status: { normal: 0, reported: 1 }  # `status` カラムで通報を管理
  
  validates :title, presence: true
  validates :content, presence: true, length: { minimum: 10 }
  validates :group_id, presence: true, allow_nil: true # 投稿が必ずグループに属するようにする
  validates :code_snippet, length: { maximum: 1000 }, allow_blank: true # コードの長さを制限



   def reported?
     status == "reported"
   end

   def liked_by?(user)
    likes.exists?(user_id: user.id)
  end
 
end