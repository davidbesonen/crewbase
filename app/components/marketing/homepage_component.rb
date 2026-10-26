# frozen_string_literal: true

class Marketing::HomepageComponent < ApplicationComponent
  extend Dry::Initializer

  option :primary_cta_label
  option :primary_cta_path
  option :show_auth_links
  option :brand_concept, default: proc { "signal" }

  renders_one :brand
  renders_one :appearance
  renders_one :concert_scene
  renders_one :workspace_preview

  private

  def pricing_plans
    PricingCatalog.plans
  end
end
