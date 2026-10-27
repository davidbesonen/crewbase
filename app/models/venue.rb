class Venue < ApplicationRecord
  FIELDS = %i[name address city state country postal_code contact_name contact_email contact_phone load_in_notes parking_notes].freeze
  belongs_to :company
  has_many :jobs, dependent: :nullify
  validates :name, presence: true, length: { maximum: 150 }
  validates :address, :city, :state, :country, :postal_code, :contact_name, :contact_phone, length: { maximum: 255 }
  validates :load_in_notes, :parking_notes, length: { maximum: 4000 }
  validates :contact_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  def formatted_address = [ address, city, state, postal_code, country ].compact_blank.join(", ")
end
