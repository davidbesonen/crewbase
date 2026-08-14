# frozen_string_literal: true

class Usr::Company::OwnerNavigationComponent < ApplicationComponent
  def initialize(company:, active:, entitlement:)
    @company = company
    @active = active.to_sym
    @entitlement = entitlement
  end

  private

  attr_reader :company, :active, :entitlement

  def feature_available?(feature)
    entitlement.allowed?(feature)
  end

  def button_class(destination, secondary: false)
    return "btn btn-sm btn-primary" if active == destination

    "btn btn-sm #{secondary ? 'btn-outline-secondary' : 'btn-outline-primary'}"
  end
end
