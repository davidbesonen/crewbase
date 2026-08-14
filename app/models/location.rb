class Location < ApplicationRecord
  has_many :location_assignments, dependent: :destroy
  has_many :locationables, through: :location_assignments

  STATES = [
    "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA",
    "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD",
    "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM",
    "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC", "SD",
    "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY"
  ]

  COUNTRIES = begin
    countries = ISO3166::Country.all.map { |c| c.iso_short_name }.compact.uniq.sort
    countries.delete("United States")
    [ "United States" ] + countries
  end.freeze

  class << self
    def ransackable_attributes(auth_object = nil)
      %w[address_line_1 address_line_2 city country id state zip_code]
    end

    def ransackable_associations(auth_object = nil)
      %w[location_assignments locationables]
    end
  end
end
