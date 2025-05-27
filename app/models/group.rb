class Group < ApplicationRecord
  belongs_to :owner, class_name: "User", foreign_key: "owner_id", optional: true

  has_many :posts, dependent: :destroy
  has_many :user_groups, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships

  has_one_attached :group_image

  has_one :owner_membership, -> { where(role: "owner") }, class_name: "Membership"
  has_one :owner, through: :owner_membership, source: :user

  # スコープ（アクティブなグループのみ取得）
  scope :active_groups, -> { where.not(name: nil) }


  enum privacy: { public_visibility: "public", private_visibility: "private", restricted_visibility: "restricted" } 
  enum category: { official_label: "official", community_label: "community", user_created_label: "user_created" } 

  validates :name, presence: true, uniqueness: true
  validates :description, length: { maximum: 500 } # 説明文の長さを制限
  validates :category, exclusion: { in: ["official_label"], message: "公式グループは作成できません" }, unless: -> { owner&.admin? }


end