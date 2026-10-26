class Marketing::BrandDirectionsComponent < ApplicationComponent
  renders_many :wordmarks

  def concepts = BrandIdentity.refinements
  def selected_brand_name = BrandIdentity.default_concept.name
  def selected?(concept) = concept.key == BrandIdentity.default_concept.key
end
