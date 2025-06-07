class DailyReportSkillTag < ApplicationRecord
  belongs_to :daily_report
  belongs_to :skill_tag
end