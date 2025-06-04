class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :source, polymorphic: true

  validates :notification_type, presence: true

  enum notification_type: { 
    membership_request: 0, 
    membership_approval: 1, 
    membership_rejection: 2, 
    member_report: 3,
    group_reported: 4 
  }

  def formatted_content
    case notification_type
    when "membership_request"
      "📝 ユーザー #{user.name} が「#{source.group.name}」への参加をリクエストしました！"
    when "membership_approval"
      "✅ 「#{source.group.name}」への参加が承認されました！"
    when "membership_rejection"
      "❌ 「#{source.group.name}」への参加が拒否されました！"
    when "member_report"
      "⚠️ ユーザー #{user.name} が「#{source.user.name}」を通報しました！"
    when "group_reported"  
      "⚠️ ユーザー #{user.name} が「#{source.name}」を通報しました！"
    else
      "通知の種類が不明です"
    end
  end
end