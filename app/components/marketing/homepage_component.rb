# frozen_string_literal: true

class Marketing::HomepageComponent < ApplicationComponent
  extend Dry::Initializer

  option :primary_cta_label
  option :primary_cta_path
  option :show_auth_links

  renders_one :brand

  private

  def pricing_plans
    [
      [ "Starter", "$19", "$190", "2 seats · 3 active jobs · 2 projects", "For small teams hiring a few roles at a time." ],
      [ "Team", "$49", "$490", "8 seats · 15 active jobs · unlimited projects", "The complete staffing workflow for growing event teams." ],
      [ "Studio", "$99", "$990", "25 seats · unlimited jobs and projects", "More capacity, analytics, onboarding, and priority support." ]
    ]
  end
end
