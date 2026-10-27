class Usr::VenueFormComponent < ApplicationComponent
  def initialize(company:, venue:)
    @company, @venue = company, venue
  end

  def form_url
    @venue.persisted? ? usr_company_venue_path(@company, @venue) : usr_company_venues_path(@company)
  end

  def input_type(key)
    { contact_email: :email_field, contact_phone: :telephone_field }.fetch(key, :text_field)
  end
end
