class ReuseGig
  Result = Data.define(:success?, :job, :error)

  def initialize(source:, actor:, title: nil, starts_on: nil, project: nil, venue: nil)
    @source, @actor, @title, @starts_on, @project, @venue = source, actor, title, starts_on, project, venue
  end

  def call
    return failure("You cannot reuse this gig.") unless @source.company.is_owner?(@actor)
    return failure("Choose a project from this company.") if @project && @project.company_id != @source.company_id
    return failure("Choose a venue from this company.") if @venue && @venue.company_id != @source.company_id
    setup = @source.is_a?(GigTemplate) ? @source.setup : GigSetup.new(job: @source).to_h
    attributes = setup.fetch("attributes").slice(*GigSetup::FIELDS, "description")
    if attributes["venue_id"].present? && !@source.company.venues.exists?(attributes["venue_id"])
      attributes["venue_id"] = nil
    end
    delta = date_shift(attributes["starts_at"])
    @job = @source.company.jobs.new(attributes.merge("title" => @title.presence || "#{attributes['title']} (Copy)", "created_by" => @actor.id, "status" => "draft", "is_active" => true))
    @job.project = @project || (@source.project if @source.is_a?(Job) && @source.project && !@source.project.archived?)
    @job.venue = @venue if @venue
    if @job.venue && @job.venue.company_id != @source.company_id
      return failure("The template venue is no longer available.")
    end
    shift_job_dates(delta)
    Job.transaction do
      @job.save!
      @job.locations = setup.fetch("locations", []).map { |values| Location.create!(values.slice(*SaveJobPosting::LOCATION_FIELDS.map(&:to_s))) }
      SyncJobVenue.new(job: @job).call
      days = copy_days(setup, delta)
      setup.fetch("positions", []).each do |values|
        @job.crew_positions.create!(values.slice(*GigSetup::POSITION_FIELDS).except("production_day_id").merge(production_day: days[values["production_day_id"].to_s]))
      end
      setup.fetch("requirements", []).each { |values| @job.job_requirements.create!(values.slice("requirement_type", "requirement_id", "importance").merge(source: :employer)) }
    end
    Result.new(success?: true, job: @job, error: nil)
  rescue ActiveRecord::RecordInvalid => error
    failure(error.record.errors.full_messages.to_sentence)
  rescue ArgumentError
    failure("Enter a valid start date.")
  end

  private

  def date_shift(original)
    return 0 if @starts_on.blank? || original.blank?
    (Date.iso8601(@starts_on.to_s) - Time.zone.parse(original).to_date).to_i
  end

  def shift_job_dates(delta)
    @job.starts_at += delta.days if @job.starts_at
    @job.ends_at += delta.days if @job.ends_at
    @job.starts_at = Date.iso8601(@starts_on.to_s).in_time_zone if @starts_on.present? && @job.starts_at.nil?
    @job.work_dates = @job.work_dates.map { |date| date + delta }
  end

  def copy_days(setup, delta)
    setup.fetch("days", []).to_h do |values|
      attributes = values.slice(*GigSetup::DAY_FIELDS)
      attributes["date"] = Date.iso8601(attributes.fetch("date")) + delta
      %w[starts_at ends_at].each { |field| attributes[field] = Time.zone.parse(attributes[field]) + delta.days if attributes[field].present? }
      [ values.fetch("id").to_s, @job.production_days.create!(attributes) ]
    end
  end

  def failure(error) = Result.new(success?: false, job: @job, error:)
end
