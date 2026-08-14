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

  private

  def candidate_jobs
    scope = Job
      .where(is_active: true, status: :published)
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

    taxonomy_matches = taxonomy_matches(job)
    return unless taxonomy_matches

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

  def matching_names(records, job)
    haystack = "#{job.title} #{job.plain_description}".downcase
    records.filter_map { |record| record.name if haystack.include?(record.name.downcase) }
  end

  def taxonomy_matches(job)
    requirements = job.job_requirements.to_a
    return legacy_taxonomy_matches(job) if requirements.empty?
    return if requirements.any? { |requirement| requirement.required? && !profile_matches?(requirement) }

    requirements.each_with_object(empty_taxonomy_matches) do |requirement, matches|
      next unless profile_matches?(requirement)

      matches.fetch(requirement.requirement_type) << requirement.requirement.name
    end
  end

  def legacy_taxonomy_matches(job)
    {
      "Occupation" => matching_names(@profile.occupations, job),
      "Skill" => matching_names(@profile.skills, job),
      "Equipment" => matching_names(@profile.equipment, job)
    }
  end

  def empty_taxonomy_matches
    { "Occupation" => [], "Skill" => [], "Equipment" => [] }
  end

  def profile_matches?(job_requirement)
    association = job_requirement.requirement_type.underscore.pluralize
    @profile.public_send(association).include?(job_requirement.requirement)
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
    JobAvailability.new(job:).conflict_dates(events: @profile.calendar_events).any?
  end

  def availability_label(job)
    job.starts_at.present? ? "Available for job dates" : "Availability not confirmed"
  end

  def compensation_reason(job)
    [ job.compensation_range, job.pay_period&.humanize&.downcase ].compact_blank.join(" ")
  end
end
