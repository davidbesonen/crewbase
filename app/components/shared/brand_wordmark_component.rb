class Shared::BrandWordmarkComponent < ApplicationComponent
  def initialize(concept: nil)
    @concept = BrandIdentity.concept(concept)
  end

  def artwork(surface)
    "/brand/knowshow-#{@concept.key}-on-#{surface}.svg"
  end
end
