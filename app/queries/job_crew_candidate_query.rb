class JobCrewCandidateQuery
  Candidate = Data.define(:profile, :reasons)

  def initialize(job:, user: nil)
    @job = job
    @user = user
  end

  def profiles
    Profile
      .includes(:user)
      .where(id: candidate_profile_ids)
      .order("users.last_name", "users.first_name", "profiles.id")
      .references(:user)
  end

  def candidates
    application_reasons = application_reasons_by_profile_id
    shortlist_reasons = shortlist_reasons_by_profile_id
    recommendation_reasons = recommendation_reasons_by_profile_id

    profiles.map do |profile|
      reasons = application_reasons.fetch(profile.id, []) + shortlist_reasons.fetch(profile.id, [])
      reasons.concat(recommendation_reasons.fetch(profile.id, []))
      Candidate.new(profile:, reasons: reasons.uniq)
    end.sort_by { |candidate| candidate_sort_key(candidate, shortlist_reasons) }
  end

  private

  attr_reader :job, :user

  def candidate_profile_ids
    (
      job.job_applications.where.not(status: :rejected).select(:profile_id).pluck(:profile_id) +
      shortlisted_profile_ids +
      recommended_profile_ids
    ).uniq - rejected_profile_ids
  end

  def application_reasons_by_profile_id
    job.job_applications.where.not(status: :rejected).pluck(:profile_id, :status).each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |(profile_id, status), reasons|
      reasons[profile_id] << "#{status.humanize} application"
    end
  end

  def rejected_profile_ids
    job.job_applications.rejected.pluck(:profile_id)
  end

  def candidate_sort_key(candidate, shortlist_reasons)
    profile = candidate.profile
    [ shortlist_reasons.key?(profile.id) ? 0 : 1, profile.user.last_name, profile.user.first_name, profile.id ]
  end

  def shortlist_reasons_by_profile_id
    CrewShortlistMembership
      .joins(:crew_shortlist)
      .where(crew_shortlists: { company_id: job.company_id })
      .pluck(:profile_id, "crew_shortlists.name")
      .each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |(profile_id, name), reasons|
        reasons[profile_id] << "#{name} shortlist"
      end
  end

  def shortlisted_profile_ids
    CrewShortlistMembership
      .joins(:crew_shortlist)
      .where(crew_shortlists: { company_id: job.company_id })
      .pluck(:profile_id)
  end

  def recommended_profile_ids
    return [] if user.blank?

    recommendation_results.map { |result| result.profile.id }
  end

  def recommendation_reasons_by_profile_id
    recommendation_results.each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |result, reasons|
      label = result.tier == :near ? "Near match: #{result.gap_reasons.to_sentence}" : "Recommended match"
      reasons[result.profile.id] << label
    end
  end

  def recommendation_results
    return [] if user.blank?

    @recommendation_results ||= CrewRecommender.new(user:, jobs: [ job ], limit: nil).results
  end
end
