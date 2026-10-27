class ProductionDay < ApplicationRecord
  belongs_to :job
  has_many :crew_positions, dependent: :nullify
  enum :day_type, { load_in: 0, show: 1, load_out: 2, travel: 3, off: 4 }
  validates :date, :day_type, presence: true
  validates :label, length: { maximum: 150 }
  validates :notes, length: { maximum: 4000 }
  validate :schedule_is_valid

  def display_name = [ date&.strftime("%b %-d"), day_type&.humanize, label.presence ].compact.join(" · ")

  private

  def schedule_is_valid
    errors.add(:ends_at, "must be after the start") if starts_at && ends_at && ends_at <= starts_at
    errors.add(:starts_at, "must fall on the selected date") if starts_at && date && starts_at.to_date != date
    return unless date
    if (job.starts_at && date < job.starts_at.to_date) || (job.ends_at && date > job.ends_at.to_date)
      errors.add(:date, "must be within the gig dates")
    end
  end
end
