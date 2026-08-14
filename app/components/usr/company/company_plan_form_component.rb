# frozen_string_literal: true

class Usr::Company::CompanyPlanFormComponent < ApplicationComponent
  extend Dry::Initializer

  option :plans
  option :visible_form

  private

  TIER_PRESENTATION = {
    "starter" => { icon: "bi-rocket-takeoff", button: "btn-outline-primary" },
    "team" => { icon: "bi-people", button: "btn-primary", badge: "Most Popular" },
    "studio" => { icon: "bi-stars", button: "btn-dark" }
  }.freeze

  def tier_key(plan)
    plan.key.presence_in(TIER_PRESENTATION.keys) || "starter"
  end

  def tier_presentation(plan)
    TIER_PRESENTATION.fetch(tier_key(plan))
  end

end
