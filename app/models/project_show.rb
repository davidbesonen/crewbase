class ProjectShow < ApplicationRecord
  # A venue-local wall-clock time, independent of the server or account timezone.
  self.skip_time_zone_conversion_for_attributes = [ :show_time ]
  belongs_to :project
  has_many :job_shows, dependent: :restrict_with_error
  has_many :jobs, through: :job_shows

  scope :chronological, -> { order(:starts_on, :id) }
  normalizes :name, :city, :state, :country, :venue_name, with: ->(value) { value&.strip }
  before_validation { self.name = city if name.blank? }
  validates :name, :city, :starts_on, presence: true
  validates :show_count, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 100 }
  validates :name, :city, :state, :country, :venue_name, length: { maximum: 150 }
  validate do
    errors.add(:show_time, "must be a valid time") if show_time_before_type_cast.present? && show_time.nil?
    errors.add(:ends_on, "must be on or after the start date") if starts_on && ends_on && ends_on < starts_on
    errors.add(:ends_on, "must be within 31 days of the start date") if starts_on && ends_on && ends_on > starts_on + 31
  end

  def work_dates = starts_on ? (starts_on..(ends_on || starts_on)).to_a : []
  def show_time_label
    "#{show_time.strftime('%-I:%M %p')} local" if show_time
  end
  def display_name
    location = [ city, state ].compact_blank.join(", ")
    [ (name unless name == city), location, starts_on&.strftime("%b %-d, %Y"), show_time_label, ("#{show_count} shows" if show_count.to_i > 1) ].compact_blank.join(" · ")
  end
end
