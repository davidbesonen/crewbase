# frozen_string_literal: true

class CrewRecommender
  Result = Data.define(
    :profile,
    :job,
    :match_reason,
    :availability_label,
    :score,
    :rating,
    :relevant_years,
    :matched_skills_and_equipment,
    :tier,
    :gap_reasons
  )

  def initialize(user:, companies: [], jobs: nil, limit: 3)
    @user = user
    @companies = companies
    @jobs = jobs
    @limit = limit
  end

  def active_jobs?
    active_jobs.any?
  end

  def results
    return @results if defined?(@results)

    ranked_results = candidate_profiles.filter_map { |profile| best_match(profile) }
      .sort_by { |result| result_sort_key(result) }
    @results = @limit ? ranked_results.first(@limit) : ranked_results
  end

  def results_for(job)
    ranked_results = candidate_profiles.filter_map { |profile| match(profile, active_job(job)) }
      .sort_by { |result| result_sort_key(result) }
    @limit ? ranked_results.first(@limit) : ranked_results
  end

  private

  def active_job(job)
    active_jobs.find { |active_job| active_job.id == job.id }
  end

  def active_jobs
    @active_jobs ||= Job
      .where(id: requested_job_ids, is_active: true, status: :published)
      .includes(:locations, :rich_text_description, { job_requirements: :requirement }, company: :locations)
      .order(starts_at: :asc, published_at: :desc)
      .to_a
  end

  def requested_job_ids
    return @jobs.map(&:id) if @jobs

    Job.where(company_id: @companies.map(&:id)).select(:id)
  end

  def candidate_profiles
    Profile
      .where(profile_type: "user")
      .where.not(user_id: @user.id)
      .where.not(completed_at: nil)
      .includes(
        :user,
        :occupations,
        :skills,
        :equipment,
        :locations,
        :experiences,
        :calendar_events,
        :received_reviews
      )
      .to_a
  end

  def best_match(profile)
    matches = active_jobs.filter_map { |job| match(profile, job) }
    matches.min_by { |result| result_sort_key(result) }
  end

  def match(profile, job)
    availability = ProfileJobAvailability.new(profile:, job:).result
    gap_reasons = []
    gap_reasons << availability.label if availability.state == :unavailable

    taxonomy_matches, missing_requirements = taxonomy_match_details(profile, job)
    gap_reasons.concat(missing_requirements.map { |requirement| "Missing required #{requirement.requirement.name}" })
    return if gap_reasons.size > 1

    occupation_matches = taxonomy_matches.fetch("Occupation")
    skill_matches = taxonomy_matches.fetch("Skill")
    equipment_matches = taxonomy_matches.fetch("Equipment")
    relevant_experiences = relevant_experiences(profile, job)
    relevant_years = relevant_experiences.sum { |experience| experience_years(experience) }
    location_score = location_proximity_score(profile, job)
    relevance_score = (occupation_matches.size * 5) +
      ((skill_matches.size + equipment_matches.size) * 3) +
      (relevant_years * 10)
    relevance_score += 2 if relevant_experiences.any? && relevant_years.zero?
    relevance_score += location_score
    return if relevance_score.zero?

    rating = average_rating(profile)
    score = relevance_score + (rating.to_f * 10)
    skills_and_equipment = skill_matches + equipment_matches

    Result.new(
      profile:,
      job:,
      match_reason: match_reason(occupation_matches, skills_and_equipment, relevant_experiences.any?),
      availability_label: availability_label(job),
      score:,
      rating:,
      relevant_years:,
      matched_skills_and_equipment: skills_and_equipment,
      tier: gap_reasons.empty? ? :full : :near,
      gap_reasons:
    )
  end

  def result_sort_key(result)
    [ result.tier == :full ? 0 : 1, -result.score, result.profile.id ]
  end

  def matching_names(records, job)
    haystack = "#{job.title} #{job.plain_description}".downcase
    records.filter_map { |record| record.name if haystack.include?(record.name.downcase) }
  end

  def taxonomy_match_details(profile, job)
    requirements = job.job_requirements.to_a
    return [ legacy_taxonomy_matches(profile, job), [] ] if requirements.empty?

    missing_requirements = requirements.select do |requirement|
      requirement.required? && !profile_matches?(profile, requirement)
    end

    matches = requirements.each_with_object(empty_taxonomy_matches) do |requirement, taxonomy_matches|
      next unless profile_matches?(profile, requirement)

      taxonomy_matches.fetch(requirement.requirement_type) << requirement.requirement.name
    end
    [ matches, missing_requirements ]
  end

  def legacy_taxonomy_matches(profile, job)
    {
      "Occupation" => matching_names(profile.occupations, job),
      "Skill" => matching_names(profile.skills, job),
      "Equipment" => matching_names(profile.equipment, job)
    }
  end

  def empty_taxonomy_matches
    { "Occupation" => [], "Skill" => [], "Equipment" => [] }
  end

  def profile_matches?(profile, job_requirement)
    association = job_requirement.requirement_type.underscore.pluralize
    profile.public_send(association).include?(job_requirement.requirement)
  end

  def relevant_experiences(profile, job)
    job_words = significant_words(job.title)
    profile.experiences.select do |experience|
      (significant_words(experience.title) & job_words).any?
    end
  end

  def experience_years(experience)
    return 0 if experience.start_year.blank?

    end_year = experience.currently_active? ? Date.current.year : experience.end_year
    return 0 if end_year.blank?

    [ end_year.to_i - experience.start_year.to_i, 0 ].max
  end

  def average_rating(profile)
    ratings = profile.received_reviews.filter_map do |review|
      review.overall_rating if review.hidden_at.blank?
    end
    return if ratings.empty?

    (ratings.sum / ratings.size.to_f).round(1)
  end

  def location_proximity_score(profile, job)
    return 0 if job.remote? || profile.locations.empty?

    target_locations = job.locations.presence || job.company&.locations || []
    profile.locations.to_a.product(target_locations.to_a).map do |profile_location, target_location|
      location_pair_score(profile_location, target_location)
    end.max || 0
  end

  def location_pair_score(profile_location, target_location)
    return 3 if same_location_value?(profile_location.city, target_location.city) &&
      compatible_location_value?(profile_location.state, target_location.state) &&
      compatible_location_value?(profile_location.country, target_location.country)
    return 2 if same_location_value?(profile_location.state, target_location.state) &&
      compatible_location_value?(profile_location.country, target_location.country)
    return 1 if same_location_value?(profile_location.country, target_location.country)

    0
  end

  def same_location_value?(first, second)
    first.present? && second.present? && first.casecmp?(second)
  end

  def compatible_location_value?(first, second)
    first.blank? || second.blank? || first.casecmp?(second)
  end

  def match_reason(occupations, skills, experience_match)
    matches = occupations + skills
    matches << "relevant experience" if matches.empty? && experience_match
    "Matches #{matches.to_sentence}"
  end

  def availability_label(job)
    job.starts_at.present? ? "Available for job dates" : "Availability not confirmed"
  end

  def significant_words(value)
    value.to_s.downcase.scan(/[a-z0-9]+/).reject { |word| word.length < 4 }
  end
end
