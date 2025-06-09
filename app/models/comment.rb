class Comment < ApplicationRecord
  after_create_commit :send_comment_notification # トランザクション外で通知作成


  belongs_to :user
  belongs_to :post

  has_one :notification, as: :source, dependent: :destroy

  after_create :create_notification

  validates :content, presence: true, length: { maximum: 500 }

  def send_comment_notification
    Notification.create!(
      user: post.user,
      notification_type: 0,
      source_id: self.id, # `source_id` のみセット
      source_type: "Comment",
      read: false
    )
  end

  def reported?
    reported
  end

end