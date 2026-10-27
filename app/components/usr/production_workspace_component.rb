class Usr::ProductionWorkspaceComponent < ApplicationComponent
  def initialize(workspace:)
    @job, @venues, @days = workspace.job, workspace.venues, workspace.days
    @new_day = workspace.schedule_item unless workspace.schedule_item&.persisted?
  end

  def schedule_url(day)
    day.persisted? ? usr_job_production_day_path(@job, day) : usr_job_production_days_path(@job)
  end

  def schedule_items = @days + [ @new_day || ProductionDay.new(date: @job.starts_at&.to_date, day_type: :show) ]
  def day_types = ProductionDay.day_types.keys.map { |key| [ UiTitle.format(key.humanize), key ] }
  def schedule_time(day)
    [ day.starts_at&.strftime("%-I:%M %p"), day.ends_at&.strftime("%b %-d, %-I:%M %p") ].compact.join(" – ").presence || "Times to be confirmed"
  end
end
