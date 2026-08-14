module Compensated
  extend ActiveSupport::Concern

  PAY_PERIODS = {
    hourly: 0,
    daily: 1,
    weekly: 2,
    biweekly: 3,
    monthly: 4,
    yearly: 5,
    per_gig: 6
  }.freeze

  included do
    enum :pay_period, PAY_PERIODS

    validates :pay_min, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
    validates :pay_max, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
    validate :pay_max_must_be_greater_than_or_equal_to_pay_min
  end

  def compensation_range
    return unless pay_min.present? || pay_max.present?

    if pay_min.present? && pay_max.present?
      "#{format_currency(pay_min)} - #{format_currency(pay_max)}"
    else
      format_currency(pay_min || pay_max)
    end
  end

  private

  def format_currency(amount)
    ApplicationController.helpers.number_to_currency(amount)
  end

  def pay_max_must_be_greater_than_or_equal_to_pay_min
    return if pay_min.blank? || pay_max.blank? || pay_max >= pay_min

    errors.add(:pay_max, "must be greater than or equal to pay min")
  end
end
