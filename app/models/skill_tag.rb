class SkillTag < ApplicationRecord
  has_many :daily_report_skill_tags
  has_many :daily_reports, through: :daily_report_skill_tags

  # impact_description メソッドを定義。ここでは仮のメッセージを返すようにする
  def impact_description
    "説明は未設定です"
  end
  
end