# Show coverage is the source of truth for a linked posting's schedule and cities.
# Booking offers keep their own immutable snapshot of agreed dates.
class ProjectJobSchedule
  def initialize(job:, show_ids: nil, schedule: nil)
    @job, @show_ids, @schedule = job, show_ids, schedule
  end

  def call
    if @job.independent?
      @job.project_shows = []
      return
    end
    invalid!("Choose a project before selecting shows.") unless @job.project
    @schedule ||= ProjectShowSchedule.new(project: @job.project)
    shows = if @job.all_shows?
      @schedule.shows
    else
      ids = Array(@show_ids || @job.project_show_ids).compact_blank.map(&:to_s).uniq
      invalid!("Choose at least one show for this role.") if ids.empty?
      records = @schedule.shows.select { |show| ids.include?(show.id.to_s) }
      raise ActiveRecord::RecordNotFound unless records.size == ids.size
      records
    end
    @job.project_shows = shows
    @job.work_dates = shows.flat_map(&:work_dates).uniq.sort
    @job.schedule_has_times = false
    @job.starts_at = @job.work_dates.first&.in_time_zone
    @job.ends_at = @job.work_dates.last&.in_time_zone&.end_of_day
    @job.locations = @schedule.locations_for(shows)
  end

  private

  def invalid!(message)
    @job.errors.add(:base, message)
    raise ActiveRecord::RecordInvalid, @job
  end
end
