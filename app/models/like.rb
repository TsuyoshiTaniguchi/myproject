class Like < ApplicationRecord
  after_create :send_like_notification  # 🔹 いいねが作成されたら通知を送信

  belongs_to :user
  belongs_to :likeable, polymorphic: true

  after_create_commit :send_like_notification

  validates_uniqueness_of :user_id, scope: [:likeable_id, :likeable_type]

  private

  def send_like_notification
    return unless likeable.is_a?(Post) #  `Post` の場合のみ通知を送る！

    Notification.create!(
      user: likeable.user, 
      notification_type: 1, 
      source: self, 
      source_id: self.id, #  `source_id` を明示的に設定！
      read: false
    )
  end


end