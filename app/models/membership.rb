class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :group

  enum role: { member: "member", owner: "owner", pending: "pending" }

  validates :user_id, uniqueness: { scope: :group_id, message: "このユーザーはすでにメンバーです" }

  def approve!
    update!(role: "member")
    Notification.create!(
      user:  user,
      source: group,
      notification_type: :membership_approval
    )
  end

  def reject!
    destroy!
    Notification.create!(
      user:  user,
      source: group,
      notification_type: :membership_rejection
    )
  end


  after_create :notify_owner_if_pending

  private
  
  def notify_owner_if_pending
    return unless role == "pending"

    Notification.create!(
      user:  group.owner,          # 受信者
      actor: user,                 # 追加するなら別 FK (省略可)
      source: self,                # Membership オブジェクト
      notification_type: :membership_request
    )
  end
end