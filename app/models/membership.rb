class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :group

  # Membership が消えるとき、source: self の通知も消す
  has_many :notifications, as: :source, dependent: :destroy

  # enum は pending→member→owner の順に
  enum role: { pending: "pending", member: "member", owner: "owner" }

  validates :user_id, uniqueness: { scope: :group_id,
                                    message: "このユーザーはすでにメンバーです" }


  # 申請が来たときオーナーに通知
  after_create :notify_owner_if_pending


  # 承認時の処理
  def approve!
    update!(role: :member)
    Notification.create!(
      user:              user,                  # 申請者に通知
      source:            self,                  # this Membership
      notification_type: :membership_approval,
      read:              false
    )
  end

  # 拒否時の処理
  def reject!
    Notification.create!(
      user:              user,                    # 申請者に通知
      source:            self,                    # この Membership を通知の source にする
      notification_type: :membership_rejection,
      read:              false
    )
    destroy!  # Membership レコードを物理削除する
  end
  

  private

  def notify_owner_if_pending
    return unless pending?
    Notification.create!(
      user:              group.owner,    # もしオーナーが管理者なら、ここに管理者のIDが入る
      source:            self,
      notification_type: :membership_request,
      read:              false
    )
  end
  
end