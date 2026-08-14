class CalendarEvent < ApplicationRecord
  belongs_to :profile

  enum :provider, { google: "google", ical: "ical", manual: "manual" }

  TYPES = %w[ blockout event ]

  validates :provider, presence: true
  validates :external_id, presence: true
end
