class CompanyManagerDashboard
  ACTIVITY_DAYS = 30
  UPCOMING_JOBS_LIMIT = 5

  def initialize(company:, today: Date.current)
    @company = company
    @today = today
  end

  def call
    {
      summary:,
      pipeline_counts: status_counts(applications, JobApplication.statuses),
      invitation_counts: status_counts(invitations, JobInvitation.statuses),
      daily_activity:,
      upcoming_jobs:,
      rates:
    }
  end

  private

  attr_reader :company, :today

  def jobs
    @jobs ||= company.jobs
  end

  def applications
    @applications ||= JobApplication.where(job_id: jobs.select(:id))
  end

  def invitations
    @invitations ||= JobInvitation.where(job_id: jobs.select(:id))
  end

  def summary
    {
      company_users: company.company_assignments.count,
      active_jobs: jobs.where(is_active: true, status: :published).count,
      active_projects: company.projects.active.where(status: %i[planning active]).count,
      applications: applications.count,
      accepted_hires: applications.accepted.count,
      pending_invitations: invitations.pending.count
    }
  end

  def status_counts(relation, statuses)
    counts = relation.group(:status).count

    statuses.each_with_object({}) do |(name, value), result|
      result[name] = counts.fetch(name, counts.fetch(value, 0))
    end
  end

  def daily_activity
    application_counts = dates_for(applications).tally
    invitation_counts = dates_for(invitations).tally

    activity_dates.map do |date|
      {
        date:,
        applications: application_counts.fetch(date, 0),
        invitations: invitation_counts.fetch(date, 0)
      }
    end
  end

  def dates_for(relation)
    relation.where(created_at: activity_range).pluck(:created_at).map { |timestamp| timestamp.to_date }
  end

  def activity_dates
    @activity_dates ||= ((today - (ACTIVITY_DAYS - 1))..today).to_a
  end

  def activity_range
    activity_dates.first.beginning_of_day..activity_dates.last.end_of_day
  end

  def upcoming_jobs
    jobs.where(is_active: true, status: :published)
      .where(starts_at: today.beginning_of_day..)
      .order(:starts_at, :id)
      .limit(UPCOMING_JOBS_LIMIT)
      .to_a
  end

  def rates
    {
      application_acceptance: percentage(applications.accepted.count, applications.count),
      invitation_acceptance: percentage(invitations.accepted.count, invitations.count)
    }
  end

  def percentage(part, total)
    return 0.0 if total.zero?

    ((part.to_f / total) * 100).round(1)
  end
end
