class SaveJobPosting
  LOCATION_FIELDS = %i[address_line_1 address_line_2 city state zip_code country].freeze

  def initialize(job:, actor:, requirements: {}, location: nil, replace_location: false, show_ids: nil)
    @job = job
    @actor = actor
    @requirements = requirements
    @location = location
    @replace_location = replace_location
    @show_ids = show_ids
  end

  def call
    job.transaction do
      stamp_status
      ProjectJobSchedule.new(job:, show_ids: @show_ids).call
      job.save!
      save_location if @replace_location && job.independent?
      JobRequirementsUpdater.new(job:, selections: @requirements).call if @requirements.any?
      JobCompletion.new(job:).call if job.completed?
      ProductEvent.record(user: @actor, name: "job_published", subject: job, event_key: job.id) if job.published?
    end
    true
  end

  private

  attr_reader :job

  def stamp_status
    attribute = { "published" => :published_at, "archived" => :archived_at,
      "closed" => :closed_at, "filled" => :filled_at, "completed" => :completed_at }[job.status]
    job[attribute] ||= Time.current if attribute
  end

  def save_location
    attributes = @location&.attributes&.symbolize_keys&.slice(*LOCATION_FIELDS) || {}
    if attributes.values.all?(&:blank?)
      job.locations = []
    else
      # Locations may also belong to profiles or other jobs. Replace the job's
      # link instead of changing a shared address in place.
      location = Location.find_by(attributes) || @location.tap(&:save!)
      job.locations = [ location ]
    end
  end
end
