# Counts product actions without collecting messages, search text, or profile details.
class ProductEvent < ApplicationRecord
  NAMES = %w[onboarding_started onboarding_completed profile_completed recommendation_shown recommendation_viewed recommendation_dismissed application_submitted job_published offer_sent offer_accepted offer_declined offer_withdrawn booking_cancelled].freeze

  belongs_to :user
  belongs_to :subject, polymorphic: true, optional: true
  belongs_to :job, optional: true
  validates :name, inclusion: { in: NAMES }
  validates :event_key, presence: true

  def self.record(user:, name:, subject: nil, event_key: nil)
    key = [ user.id, name, event_key || SecureRandom.uuid ].join(":")
    create_or_find_by!(event_key: key) do |event|
      event.user = user
      event.name = name
      event.subject = subject
      event.job = subject.is_a?(Job) ? subject : (subject.job if subject.respond_to?(:job))
    end
  end
end
