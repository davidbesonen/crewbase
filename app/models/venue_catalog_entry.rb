class VenueCatalogEntry < ApplicationRecord
  LOCATION_FIELDS = %w[name address city state postal_code country].freeze

  before_validation :normalize_search_text
  validates :source_key, :name, :country, presence: true

  def self.search_text_for(attributes)
    LOCATION_FIELDS.map { |field| attributes[field] }.compact.join(" ").parameterize(separator: " ")
  end

  def search_result
    attributes.slice("id", *LOCATION_FIELDS).merge("label" => [ name, [ city, state ].compact_blank.join(", ") ].compact_blank.join(" — "))
  end

  def venue_attributes = attributes.slice(*LOCATION_FIELDS)

  private

  def normalize_search_text
    self.search_text = self.class.search_text_for(attributes)
  end
end
