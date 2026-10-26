class RecommendationFeedback < ApplicationRecord
  REASONS = { "not_relevant" => "Not relevant to my work", "location" => "Location doesn't work", "pay" => "Pay doesn't work", "timing" => "Dates don't work" }.freeze
  belongs_to :user
  belongs_to :job
  validates :reason, inclusion: { in: REASONS.keys }
  validates :job_id, uniqueness: { scope: :user_id }
end
