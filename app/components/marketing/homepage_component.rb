# frozen_string_literal: true

class Marketing::HomepageComponent < ApplicationComponent
  extend Dry::Initializer

  option :primary_cta_label
  option :primary_cta_path
  option :show_auth_links

  renders_one :brand
  renders_one :appearance

  private

  def pricing_plans
    PricingCatalog.plans
  end
end
