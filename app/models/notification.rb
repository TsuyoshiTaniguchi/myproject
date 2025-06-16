class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :source, polymorphic: true

  validates :notification_type, presence: true

  enum notification_type: {
    membership_request:   0,
    membership_approval:  1,
    membership_rejection: 2,
    member_report:        3,
    group_reported:       4,
    comment_report:       5
  }

  scope :unread, -> { where(read: false) }


  def formatted_content
    text =
      if attribute_names.include?('content') && self['content'].present?
        self['content']
      else
        notification_type.to_s.titleize
      end

    md = /\A\[(.+?)\]\((https?:\/\/.+?)\)\z/.match(text)
    return text unless md

    link_text, url = md[1], md[2]
    "<a href='#{url}' target='_blank' rel='noopener'>#{link_text}</a>".html_safe
  end
end