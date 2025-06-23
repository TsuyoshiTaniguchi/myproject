class DailyReport < ApplicationRecord
  belongs_to :user
  has_many :tasks, dependent: :destroy

  # 公開／非公開の設定
  enum visibility: { public_report: 0, private_report: 1 }

  # 管理者は全件、本人は全件、それ以外は公開のみ取得する
  scope :accessible_for, ->(viewer, owner_id) {
    # viewer が Admin モデルかどうか
    is_admin = viewer.is_a?(Admin)
    # viewer が User モデルで owner_id と同じかどうか
    is_owner = viewer.respond_to?(:id) && viewer.id == owner_id

    if is_admin || is_owner
      where(user_id: owner_id)
    else
      where(user_id: owner_id, visibility: :public_report)
    end
  }

  reverse_geocoded_by :latitude, :longitude do |report, results|
    geo = results&.first or next

    # Geocoder::Result の city メソッドで「市区町村」取得を試みる
    # なければ state（都道府県）、country（国名）にフォールバック
    report.location =
      geo.city.presence ||
      geo.state.presence ||
      geo.country.presence ||
      report.location
  end



  # バリデーション
  validates :date,     presence: true
  validates :location, presence: true
  validates :content,  presence: true

  # タスク達成度と自己評価について（1〜10の数値）
  validates :task_achievement, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }, allow_nil: true
  validates :self_evaluation,  numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }, allow_nil: true

  # 将来成長予測用の属性
  validates :future_goal_value,
    numericality: {
      only_integer: false,
      greater_than_or_equal_to: 1,
      less_than_or_equal_to: 10
    },
    allow_blank: true

  validates :future_goal_days,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 1,
      less_than_or_equal_to: 365
    },
    allow_blank: true


  # app/models/daily_report.rb
  scope :accessible_for, ->(current_user, user_id) {
    where(user_id: user_id)
      .yield_self { |rel|
        if current_user.admin?
          rel
        elsif current_user.id == user_id
          rel
        else
          rel.where(visibility: 'public_report')
        end
      }
  }

  
  # タスク合計数
  def total_tasks_count
    tasks.count
  end

  # 完了タスク数
  def completed_tasks_count
    tasks.where(completed: true).count
  end

  def history_dates
    user.daily_reports.order(:date).pluck(:date).map { |d| d.strftime("%Y-%m-%d") }
  end
  
  def history_rates
    user.daily_reports.order(:date).map(&:achievement_rate)
  end
  

  # 前回の日報を取得するメソッド
  def previous_report
    self.class.where(user_id: user_id).where('date < ?', date).order(date: :desc).first
  end

  # タスク達成度スコア（0..10）
  def task_score
    return nil if tasks.empty?
    done  = tasks.where(completed: true).count
    total = tasks.size
    ((done.to_f / total) * 10).round(1)
  end

  # “生”の達成率（％） ※100％超えを許容
  def raw_achievement_rate
    return nil unless future_goal_value.to_i.positive? && task_score
    ((task_score / future_goal_value.to_f) * 100).round(1)
  end

  # 表示用達成率（0..100） ※ここで必ずクリップ
  def achievement_rate
    r = raw_achievement_rate or return nil
    # Rails 6+ なら clamp、5以前なら [r,100].min
    r.clamp(0, 100)
  end

  # パフォーマンススコア（タスク達成度と自己評価の平均、0..10）
  def performance_score
    return nil unless task_score && self_evaluation.present?
    # self_evaluation (1..5) → *2 で 0..10 にスケールアップ
    self10 = self_evaluation.to_f * 2
    ((task_score + self10) / 2.0).round(1)
  end


  # 将来予測（0..100）を日数分返す
  def predicted_achievement_rates
    return [] unless future_goal_value.to_i.positive? && future_goal_days.to_i.positive?
    start = achievement_rate.to_f
    goal  = future_goal_value.to_f

    (1..future_goal_days).map do |i|
      rate = (start + (goal - start) * i / future_goal_days).round(1)
      rate.clamp(0, 100)
    end
  end

end