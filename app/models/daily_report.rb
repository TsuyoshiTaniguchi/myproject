class DailyReport < ApplicationRecord
  belongs_to :user

  has_many :daily_report_skill_tags
  has_many :skill_tags, through: :daily_report_skill_tags

  #  日報の充実度を計算（文字数 + タグ数）
  def importance_level
    content_length = self.content.length
    tag_count = self.tags.count
    (content_length / 100) + tag_count
  end

  def calendar_data
    reports = DailyReport.all.select(:id, :date, :title)
    render json: reports.map { |report|
      {
        id: report.id,
        title: report.title,
        start: report.date.strftime("%Y-%m-%d"),
        url: daily_report_path(report)
      }
    }
  end

  enum visibility: { public_report: 0, private_report: 1 } # 公開・非公開設定

  validates :date, presence: true
  validates :location, presence: true
  validates :content, presence: true

end
