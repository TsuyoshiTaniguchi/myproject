class SkillTag < ApplicationRecord
  has_many :daily_report_skill_tags
  has_many :daily_reports, through: :daily_report_skill_tags
end