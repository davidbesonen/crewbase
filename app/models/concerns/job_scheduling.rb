module JobScheduling
  extend ActiveSupport::Concern

  included do
    before_validation :normalize_date_only_schedule
    validate :end_must_follow_start
  end

  private

  def normalize_date_only_schedule
    return if schedule_has_times?

    self.starts_at = starts_at.beginning_of_day if starts_at
    self.ends_at = ends_at.end_of_day if ends_at
  end

  def end_must_follow_start
    return unless starts_at && ends_at && ends_at <= starts_at

    errors.add(:ends_at, "must be after the start")
  end
end
