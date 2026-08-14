class UserPlan < ApplicationRecord
  has_many :user_subscriptions, dependent: :restrict_with_error
  has_many :users, through: :user_subscriptions

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true
  validates :monthly_price_cents, :annual_price_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :stripe_monthly_price_id, :stripe_annual_price_id, uniqueness: true, allow_nil: true

  scope :active, -> { where(active: true).order(:monthly_price_cents, :id) }
end
