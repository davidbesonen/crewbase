class ProductionWorkspace
  attr_reader :job, :schedule_item

  def initialize(job:, schedule_item: nil)
    @job, @schedule_item = job, schedule_item
  end

  def venues = @venues ||= job.company.venues.order(:name).to_a

  def days
    @days ||= job.production_days.order(:date, :starts_at, :id).map do |day|
      day.id == schedule_item&.id ? schedule_item : day
    end
  end
end
