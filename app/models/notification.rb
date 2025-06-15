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
  # 'content' カラムが存在していて、かつ値が存在すればその値を使う
  if attribute_names.include?("content") && self["content"].present?
    text = self["content"]
  else
    # カラムがない・空の場合は、notification_type を見やすい形（タイトルケース）に変換して使う
    text = notification_type.to_s.titleize
  end

  # Markdown 形式のリンク [リンクテキスト](URL) にマッチするかチェックする
  md = /\A\[(.+?)\]\((https?:\/\/.+?)\)\z/.match(text)
  return text unless md

  # マッチしていればリンクタグに変換して返す
  link_text, url = md[1], md[2]
  "<a href='#{url}' target='_blank' rel='noopener'>#{link_text}</a>".html_safe
end
end        
