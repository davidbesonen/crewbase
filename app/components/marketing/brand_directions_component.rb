class Marketing::BrandDirectionsComponent < ApplicationComponent
  renders_many :wordmarks

  def concepts = BrandIdentity::CONCEPTS
end
