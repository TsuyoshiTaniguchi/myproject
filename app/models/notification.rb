class Notification < ApplicationRecord

  belongs_to :user
  belongs_to :source, polymorphic: true # ポリモーフィック設定で通知対象を柔軟に

  # スコープ
  scope :unread, -> { where(read_at: nil) } # 未読通知の取得


  validates :notification_type, presence: true
  validates :source_id, presence: true
  validates :source_type, presence: true

  # 既読処理
  def mark_as_read!
    update(read_at: Time.current)
  end
end