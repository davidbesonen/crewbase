class Usr::JobScheduleComponent < ApplicationComponent
  def initialize(job:)
    @job = job
  end

  def shows = @job.project_shows.to_a.sort_by { |show| [ show.starts_on, show.id ] }

  def entries
    [ [ "Starts", @job.starts_at ], [ "Ends", @job.ends_at ] ].map do |label, value|
      { label: label, text: schedule_text(value) }
    end
  end

  private

  def schedule_text(value)
    return "Flexible / Not listed" unless value
    return I18n.l(value.to_date, format: :long) unless @job.schedule_has_times?

    "#{I18n.l(value, format: :long)} (#{Time.zone.name})"
  end
end
