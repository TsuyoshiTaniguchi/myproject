class DailyReport < ApplicationRecord
  belongs_to :user

  has_many :daily_report_skill_tags
  has_many :skill_tags, through: :daily_report_skill_tags

  # learned_lessons メソッド：現時点では空の配列を返す
  def learned_lessons
    []
  end

  # もしくは、content に特定の形式で「学び」が記載されているならパースする処理も検討可能
  # 例:
  # def learned_lessons
  #   content.to_s.split("\n").select { |line| line.start_with?("学び:") }
  # end

  # 将来的な技術強化プラン（future_goals）のプレースホルダー（現状は空の配列）
  def future_goals
    []
  end

  # 現在のレポートより前の日付の最新（直前）の日報を返す  
  # ※ self.class を使うことで、名前空間の影響を避けます。
  def previous_report
    self.class.where("user_id = ? AND date < ?", user_id, date)
              .order(date: :desc)
              .first
  end

  # 日報の充実度を計算（例：文字数 + タグ数）
  # importance_level をもとに impact_score を計算する例
  def impact_score
    score = importance_level
    # 0～10 の間に収める例（必要に応じて調整してください）
    [score, 10].min
  end

  def importance_level
    content_length = content.length
    tag_count = skill_tags.count
    (content_length / 100) + tag_count
  end

  # カレンダー用のデータハッシュを返す（全日報対象）
  # self.class.all とすることで、名前解決のトラブルを防ぎます。
  def calendar_data_hash
    self.class.all.map do |report|
      {
        id: report.id,
        title: report.location.present? ? report.location : report.content.truncate(30),
        start: report.date.strftime("%Y-%m-%d"),
        # URL生成は通常コントローラー側で行うのが好ましいですが、例として
        url: Rails.application.routes.url_helpers.daily_report_path(report)
      }
    end
  end

  enum visibility: { public_report: 0, private_report: 1 } # 公開・非公開設定

  validates :date, presence: true
  validates :location, presence: true
  validates :content, presence: true
end