class Group < ApplicationRecord
  belongs_to :owner, class_name: "User", foreign_key: "owner_id" #  所有者の関連付け

  has_many :posts, dependent: :destroy
  has_many :user_groups, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships

  has_one_attached :group_image

  has_many :owner_memberships, -> { where(role: "owner") }, class_name: "Membership"
  has_many :owners, through: :owner_memberships, source: :user  # `has_one` → `has_many` に修正！

  # スコープ（アクティブなグループのみ取得）
  scope :active_groups, -> { where.not(name: nil) }


  enum privacy: { public_visibility: "public", private_visibility: "private", restricted_visibility: "restricted" } 
  enum category: { official_label: "official_label", user_created_label: "user_created_label" } 
  enum join_policy: { open: "open", admin_only: "admin_only", invite_only: "invite_only" }

  def assign_owner
    admin = User.find_by(role: "admin")
    if admin
      self.owner = admin
      self.owner_memberships.build(user: admin, role: "owner", group: self) # `group: self` を追加！
    end
  end
  
  
  validates :name, presence: true, uniqueness: true
  validates :description, length: { maximum: 500 } # 説明文の長さを制限
  validates :category, exclusion: { in: ["official_label"], message: "公式グループは管理者のみ作成できます" }, unless: -> { owner&.admin? }
end