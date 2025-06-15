class Comment < ApplicationRecord
  after_create_commit :send_comment_notification # トランザクション外で通知作成

  belongs_to :user
  belongs_to :post

  has_one :notification, as: :source, dependent: :destroy

  validates :content, presence: true, length: { maximum: 500 }

  def send_comment_notification
    # コメントを作った人（self.user_id）と投稿者（post.user_id）が同じなら、
    # 自分への通知なので、処理を中断（return）して通知を作らない
    return if post.user_id == self.user_id
  
    Notification.create!(
      user: post.user,
      notification_type: 0,
      source_id: self.id,
      source_type: "Comment",
      read: false
    )
  end
  

  def reported?
    reported
  end

end