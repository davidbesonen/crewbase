class CompanyPlan < ApplicationRecord
  STATUSES = %w[incomplete incomplete_expired trialing active past_due canceled unpaid paused replaced].freeze
  ENTITLED_STATUSES = %w[trialing active].freeze
  BILLING_INTERVALS = %w[monthly annual].freeze

  belongs_to :company
  belongs_to :plan

  validates :status, inclusion: { in: STATUSES }
  validates :billing_interval, inclusion: { in: BILLING_INTERVALS }, allow_nil: true
  validates :stripe_subscription_id, :stripe_subscription_item_id, uniqueness: true, allow_nil: true

  scope :entitled, -> { where(status: ENTITLED_STATUSES) }
  scope :current, -> { entitled.order(created_at: :desc, id: :desc) }

  def entitled?
    status.in?(ENTITLED_STATUSES)
  end
end
