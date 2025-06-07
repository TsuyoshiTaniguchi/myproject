class Tag < ApplicationRecord
  has_many :daily_report_tags
  has_many :daily_reports, through: :daily_report_tags
  belongs_to :daily_report
  belongs_to :skill_tag

end

