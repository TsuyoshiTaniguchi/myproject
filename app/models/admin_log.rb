class AdminLog < ApplicationRecord
  # アソシエーション
  belongs_to :admin
  belongs_to :target, polymorphic: true # ポリモーフィック関連を追加

  # バリデーション
  validates :action, presence: true
  validates :target_type, presence: true
  validates :target_id, presence: true

  # ログのスコープ（最新順）
  scope :recent, -> { order(created_at: :desc) }

  # ログ作成メソッド
  def self.record(admin, action, target)
    create(admin: admin, action: action, target: target)
  end
end