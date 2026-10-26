class DashboardWorkSchedule
  def initialize(profile:, limit: 3)
    @profile = profile
    @limit = limit
  end

  def booked_jobs
    offers = JobOffer.accepted.where(profile:).includes(:job_application).index_by { |offer| offer.job_application.job_id }
    confirmed_jobs.where(status: %i[published closed filled]).includes(:company).filter_map do |job|
      if (offer = offers[job.id])
        job.assign_attributes(starts_at: offer.starts_at, ends_at: offer.ends_at)
        job.readonly!
      end
      job if job.starts_at && (job.starts_at >= Time.current || (job.ends_at && job.ends_at >= Time.current))
    end.sort_by { |job| [ job.starts_at, job.id ] }.first(limit)
  end

  def opportunities
    Job.upcoming
      .where.not(id: confirmed_jobs.select(:id))
      .where.not(company_id: profile.user.owned_companies.select(:id))
      .includes(:company)
      .limit(limit)
      .to_a
  end

  private

  attr_reader :profile, :limit

  def confirmed_jobs
    accepted_job_ids = profile.job_applications.accepted.select(:job_id)
    assigned_job_ids = profile.crew_positions.select(:job_id)

    # Invitations are invitations to apply; only acceptance or a crew assignment books work.
    Job.where(id: accepted_job_ids).or(Job.where(id: assigned_job_ids))
  end
end
