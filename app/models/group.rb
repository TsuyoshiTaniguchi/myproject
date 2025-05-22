class Group < ApplicationRecord

  has_many :posts, dependent: :destroy
  has_many :user_groups, dependent: :destroy
  has_many :users, through: :user_groups


  validates :name, presence: true, uniqueness: true
  validates :description, length: { maximum: 500 } # 説明文の長さを制限

  # スコープ（アクティブなグループのみ取得）
  scope :active_groups, -> { where.not(name: nil) }
end