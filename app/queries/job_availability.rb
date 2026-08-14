class JobAvailability
  def initialize(job:)
    @job = job
  end

  def conflict_dates(events:)
    Array(events).filter_map do |event|
      next unless event.event_type == "blockout"

      overlap_dates(event)
    end.flatten.uniq.sort
  end

  private

  attr_reader :job

  def overlap_dates(event)
    event_start = (event.from_date || event.to_date)&.to_date
    event_end = (event.to_date || event.from_date)&.to_date
    return [] if event_start.blank? || event_end.blank?

    if job.work_dates.any?
      job.work_dates.select { |date| date.between?(event_start, event_end) }
    elsif job.starts_at.present?
      job_start = job.starts_at.to_date
      job_end = (job.ends_at || job.starts_at).to_date
      ([ event_start, job_start ].max..[ event_end, job_end ].min).to_a
    else
      []
    end
  end
end
