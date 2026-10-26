# frozen_string_literal: true

class WorkerJobRecommender
  Result = Data.define(
    :job,
    :match_reasons,
    :availability_label,
    :score,
    :matched_terms
  )

  def initialize(profile:, limit: 5, jobs: nil)
    @profile = profile
    @limit = limit
    @jobs = jobs
  end

  def results
    ranked = candidate_jobs.filter_map { |job| recommendation_for(job) }
      .sort_by { |result| [ -result.score, -result.job.published_at.to_i, result.job.id ] }
    @limit ? ranked.first(@limit) : ranked
  end

  def matching_profile?
    [ @profile.occupations, @profile.capability_keys, @profile.equipment_family_keys, @profile.reported_skills, @profile.reported_equipment ].any?(&:any?)
  end

  private

  def candidate_jobs
    scope = Job.accepting_applications
      .where.not(id: RecommendationFeedback.where(user: @profile.user).select(:job_id))
      .where.not(company_id: owned_company_ids)
      .includes(
        :locations,
        :rich_text_description,
        { job_requirements: :requirement },
        company: [ :industries, :locations ]
      )
    scope = scope.where(id: @jobs.map(&:id)) if @jobs
    scope.to_a
  end

  def owned_company_ids
    @owned_company_ids ||= @profile.user.owned_companies.select(:id)
  end

  def recommendation_for(job)
    return if unavailable?(job)

    experience_match = ExperienceMatch.new(profile: @profile, job: job)
    return if experience_match.missing_requirements.any?

    taxonomy_matches = experience_match.names

    occupations = taxonomy_matches.fetch("Occupation")
    skills = taxonomy_matches.fetch("Skill")
    equipment = taxonomy_matches.fetch("Equipment")
    matched_terms = occupations + skills + equipment
    return if matched_terms.empty?

    location_reason, location_score = location_match(job)
    availability_label = availability_label(job)
    reasons = [ "Matches #{matched_terms.to_sentence}" ]
    reasons << location_reason if location_reason
    reasons << compensation_reason(job) if job.compensation_range.present?
    reasons << availability_label

    Result.new(
      job:,
      match_reasons: reasons,
      availability_label:,
      score: (occupations.size * 8) + (skills.size * 5) + (equipment.size * 5) + location_score,
      matched_terms:
    )
  end

  def location_match(job)
    return [ "Remote role", 2 ] if job.remote?
    return [ nil, 0 ] if @profile.locations.empty?

    target_locations = job.locations.presence || job.company&.locations || []
    matches = @profile.locations.to_a.product(target_locations.to_a).filter_map do |profile_location, job_location|
      location_match_for(profile_location, job_location)
    end
    matches.max_by(&:last) || [ nil, 0 ]
  end

  def location_match_for(profile_location, job_location)
    if same?(profile_location.city, job_location.city) &&
        compatible?(profile_location.state, job_location.state) &&
        compatible?(profile_location.country, job_location.country)
      [ "Located in #{[ job_location.city, job_location.state ].compact_blank.join(', ')}", 4 ]
    elsif same?(profile_location.state, job_location.state) &&
        compatible?(profile_location.country, job_location.country)
      [ "Located in #{job_location.state}", 3 ]
    elsif same?(profile_location.country, job_location.country)
      [ "Located in #{job_location.country}", 1 ]
    end
  end

  def same?(first, second)
    first.present? && second.present? && first.casecmp?(second)
  end

  def compatible?(first, second)
    first.blank? || second.blank? || first.casecmp?(second)
  end

  def unavailable?(job)
    availability(job).state == :unavailable
  end

  def availability_label(job)
    availability(job).label
  end

  def availability(job)
    @availability ||= {}
    @availability[job.id] ||= ProfileJobAvailability.new(profile: @profile, job:, bookings: booked_schedules).result
  end

  def booked_schedules
    @booked_schedules ||= BookedSchedules.new(profile_ids: [ @profile.id ]).results.fetch(@profile.id, [])
  end

  def compensation_reason(job)
    [ job.compensation_range, job.pay_period&.humanize&.downcase ].compact_blank.join(" ")
  end
end
