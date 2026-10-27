class ProjectShow < ApplicationRecord
  belongs_to :project
  has_many :job_shows, dependent: :restrict_with_error
  has_many :jobs, through: :job_shows

  scope :chronological, -> { order(:starts_on, :id) }
  normalizes :name, :city, :state, :country, :venue_name, with: ->(value) { value&.strip }
  validates :name, :city, :starts_on, presence: true
  validates :name, :city, :state, :country, :venue_name, length: { maximum: 150 }
  validate do
    errors.add(:ends_on, "must be on or after the start date") if starts_on && ends_on && ends_on < starts_on
    errors.add(:ends_on, "must be within 31 days of the start date") if starts_on && ends_on && ends_on > starts_on + 31
  end

  def work_dates = starts_on ? (starts_on..(ends_on || starts_on)).to_a : []
  def display_name = [ name, [ city, state ].compact_blank.join(", "), starts_on&.strftime("%b %-d, %Y") ].compact_blank.join(" · ")
end
