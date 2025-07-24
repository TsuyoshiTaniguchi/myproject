class Notification < ApplicationRecord
  include Rails.application.routes.url_helpers

  belongs_to :user  # 通知の受信者（管理者の User レコード）
  belongs_to :source, polymorphic: true

  validates :notification_type, presence: true

  enum notification_type: {
    membership_request:   0,
    membership_approval:  1,
    membership_rejection: 2,
    member_report:        3,
    group_reported:       4,
    comment_report:       5,
    admin_alert:          6,
    post_report:          7,
    like:                 8,
    comment:              9
  }

  scope :unread, -> { where(read: false) }

  # 送信者（発生元）の名前を返す
  def sender_name
    if source.present?
      if source.respond_to?(:user) && source.user.present?
        source.user.name
      elsif source.respond_to?(:name) && source.name.present?
        source.name
      else
        "不明"
      end
    else
      "不明"
    end
  end

  # 通知内容（リンクテキスト）を整形する
  def link_text
    case notification_type
    when "membership_request"
      grp = source.respond_to?(:group) ? source.group : nil
      "<i class='bi bi-person-plus'></i> #{sender_name} さんが「#{grp.try(:name) || 'グループ名不明'}」に参加申請しました".html_safe
    when "membership_approval"
      grp = source.respond_to?(:group) ? source.group : nil
      "<i class='bi bi-check2-circle'></i> あなたの「#{grp.try(:name) || 'グループ名不明'}」参加申請が承認されました！".html_safe
    when "membership_rejection"
      grp = source.respond_to?(:group) ? source.group : nil
      "<i class='bi bi-x-circle'></i> あなたの「#{grp.try(:name) || 'グループ名不明'}」参加申請が却下されました…".html_safe
    when "like"
      "<i class='bi bi-hand-thumbs-up'></i> #{sender_name} さんがあなたの投稿をいいねしました！".html_safe
    when "comment"
      "<i class='bi bi-chat-left-text'></i> #{sender_name} さんがあなたの投稿にコメントしました！".html_safe
    when "group_reported"
      "<i class='bi bi-exclamation-circle'></i> #{sender_name} さんがグループを通報しました".html_safe
    when "post_report"
      "<i class='bi bi-exclamation-triangle'></i> #{sender_name} さんが投稿を通報しました".html_safe
    when "comment_report"
      "<i class='bi bi-exclamation-triangle'></i> #{sender_name} さんがコメントを通報しました".html_safe
    when "member_report"
      "<i class='bi bi-exclamation-triangle'></i> #{sender_name} さんがメンバーを通報しました".html_safe
    else
      formatted_content
    end
  end

  # 以下は既存の処理。既読フラグやリンク先など
  def link_url
    case notification_type
    when "membership_request", "membership_approval", "membership_rejection",
         "like", "comment", "post_report", "comment_report", "member_report", "group_reported"
      notification_path(self)
    when "admin_alert"
      notifications_path
    else
      notifications_path
    end
  end

  def link_method
    case notification_type
    when "like", "comment", "post_report", "comment_report", "member_report", "group_reported"
      :patch
    when "membership_request", "membership_approval", "membership_rejection"
      :get
    else
      :get
    end
  end

  def formatted_content
    text =
      if attribute_names.include?('content') && self['content'].present?
        self['content']
      else
        notification_type.to_s.titleize
      end

    md = /\A

\[(.+?)\]

\((https?:\/\/.+?)\)\z/.match(text)
    return text unless md

    link_text, url = md[1], md[2]
    "<a href='#{url}' target='_blank' rel='noopener'>#{link_text}</a>".html_safe
  end
end
