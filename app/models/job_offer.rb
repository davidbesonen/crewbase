class JobOffer < ApplicationRecord
  belongs_to :job_application
  belongs_to :profile
  belongs_to :sender, class_name: "User"
  belongs_to :crew_position, optional: true
  belongs_to :cancelled_by, class_name: "User", optional: true
  has_one :job, through: :job_application
  has_one :crew_assignment, dependent: :nullify

  enum :status, { pending: 0, accepted: 1, declined: 2, withdrawn: 3, expired: 4, cancelled: 5 }

  scope :visible_to, ->(user) {
    joins(job_application: :job).where(profile_id: user.user_profile&.id)
      .or(joins(job_application: :job).where(jobs: { company_id: user.owned_companies.select(:id) }))
  }
  scope :awaiting_response, -> {
    pending.joins(:job).merge(Job.not_ended.where.not(status: %i[archived completed]))
      .where("job_offers.ends_at > ?", Time.current)
      .where("job_offers.expires_at IS NULL OR job_offers.expires_at > ?", Time.current)
  }
  scope :current_bookings, -> {
    accepted.joins(:job).where.not(jobs: { status: %i[archived completed] })
      .where("job_offers.ends_at > ?", Time.current)
  }

  validates :role, :starts_at, :ends_at, :currency, :pay_unit, presence: true
  validates :rate, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, format: { with: /\A[A-Z]{3}\z/ }
  validates :pay_unit, inclusion: { in: Compensated::PAY_PERIODS.keys.map(&:to_s) }
  validate :valid_dates
  validate :immutable_terms, on: :update
  validate :future_terms, on: :create

  def effective_status
    return status unless pending?

    [ expires_at, ends_at ].compact.any? { |deadline| deadline <= Time.current } ? "expired" : status
  end

  def recipient?(user)
    profile.user_id == user&.id
  end

  def work_dates
    []
  end

  private

  def valid_dates
    errors.add(:ends_at, "must be after the start") if starts_at && ends_at && ends_at <= starts_at
    errors.add(:expires_at, "must be before work begins") if expires_at && starts_at && expires_at >= starts_at
  end

  def future_terms
    errors.add(:ends_at, "must be in the future") if ends_at && ends_at <= Time.current
    errors.add(:expires_at, "must be in the future") if expires_at && expires_at <= Time.current
  end

  def immutable_terms
    fields = %w[job_application_id profile_id sender_id crew_position_id role starts_at ends_at rate currency pay_unit terms expires_at]
    errors.add(:base, "Offer terms cannot be edited. Send a new offer for changed terms.") if (changes.keys & fields).any?
  end
end
