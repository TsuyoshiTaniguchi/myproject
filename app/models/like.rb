class Like < ApplicationRecord
  after_create_commit # いいねが作成されたら通知を送信

  belongs_to :user
  belongs_to :likeable, polymorphic: true

  after_create_commit :send_like_notification

  validates_uniqueness_of :user_id, scope: [:likeable_id, :likeable_type]

  private

  def send_like_notification
    # Post の場合のみ処理する
    return unless likeable.is_a?(Post)
    
    # 自分自身の投稿に対するいいねなら通知は送らない
    return if likeable.user == self.user

    Notification.create!(
      user: likeable.user,         # 通知先は、投稿の作成者
      notification_type: 1,         # notification_type を数値で指定していますが、enum を利用しているならシンボルにすることも可能です
      source: self,                 # 通知の元はこの Like
      source_id: self.id,           # 明示的に Like の id を設定
      read: false
    )
  end



end