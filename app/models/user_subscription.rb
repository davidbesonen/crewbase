class UserSubscription < ApplicationRecord
  STATUSES = CompanyPlan::STATUSES
  ENTITLED_STATUSES = CompanyPlan::ENTITLED_STATUSES
  BILLING_INTERVALS = CompanyPlan::BILLING_INTERVALS

  belongs_to :user
  belongs_to :user_plan

  validates :status, inclusion: { in: STATUSES }
  validates :billing_interval, inclusion: { in: BILLING_INTERVALS }, allow_nil: true
  validates :stripe_subscription_id, :stripe_subscription_item_id, uniqueness: true, allow_nil: true

  scope :entitled, -> { where(status: ENTITLED_STATUSES) }
  scope :current, -> { entitled.order(created_at: :desc, id: :desc) }

  def entitled?
    status.in?(ENTITLED_STATUSES)
  end
end
