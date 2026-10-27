class CompanyAssignment < ApplicationRecord
  belongs_to :company
  belongs_to :user
  belongs_to :profile, optional: true

  ROLES = %w[owner member].freeze
  # Earlier employee assignments were stored as "member". Both represent
  # company staff; a CrewMember roster contact alone grants no staff access.
  ROSTER_UPLOAD_ROLES = %w[owner employee member].freeze

  validate :company_user_must_be_within_plan_limit, on: :create

  private

  def company_user_must_be_within_plan_limit
    return unless company&.current_plan&.data&.key?("seats_limit")

    entitlement = CompanyPlanEntitlement.new(company)
    return if entitlement.within_limit?(:company_users)

    errors.add(:base, "#{entitlement.current_plan.name} plan allows #{entitlement.limit(:company_users)} company users")
  end
end
