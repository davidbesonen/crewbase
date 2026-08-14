class CreditFromJobApplication
  def initialize(job_application:)
    @job_application = job_application
  end

  def call
    raise ActiveRecord::RecordNotFound unless creditable?

    job_application.profile.credits.find_or_create_by!(job: job_application.job) do |credit|
      job = job_application.job
      credit.project = nil
      credit.company = job.company
      credit.role = job.title
      credit.project_name = job.title
      credit.company_name = job.company&.name
      credit.starts_on = job.starts_at&.to_date
      credit.ends_on = job.ends_at&.to_date
      credit.location = job.formatted_location
      credit.verified_at = job.filled_at || job_application.decision_at || Time.current
    end
  end

  private

  attr_reader :job_application

  def creditable?
    job_application.accepted? && job_application.job.filled?
  end
end
