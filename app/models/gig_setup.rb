class GigSetup
  FIELDS = %w[title workplace_type employment_type posting_type audience requires_travel pay_min pay_max pay_period
    questions starts_at ends_at schedule_has_times work_dates required_capability_keys preferred_capability_keys
    required_equipment_family_keys preferred_equipment_family_keys required_skills_text preferred_skills_text
    required_equipment_text preferred_equipment_text venue_id briefing_notes production_contact_name production_contact_email production_contact_phone].freeze
  POSITION_FIELDS = %w[title description headcount pay_min pay_max pay_period production_day_id].freeze
  DAY_FIELDS = %w[date day_type label starts_at ends_at notes].freeze

  def initialize(job:)
    @job = job
  end

  def to_h
    {
      "attributes" => @job.attributes.slice(*FIELDS).merge("description" => @job.description.body.to_s),
      "locations" => @job.locations.map { |location| location.attributes.slice(*SaveJobPosting::LOCATION_FIELDS.map(&:to_s)) },
      "positions" => @job.crew_positions.map { |position| position.attributes.slice(*POSITION_FIELDS) },
      "days" => @job.production_days.map { |day| day.attributes.slice("id", *DAY_FIELDS).merge("day_type" => day.day_type) },
      "requirements" => @job.job_requirements.map { |requirement| requirement.attributes.slice("requirement_type", "requirement_id", "importance") }
    }.as_json
  end
end
