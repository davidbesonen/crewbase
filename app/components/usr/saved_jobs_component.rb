class Usr::SavedJobsComponent < ApplicationComponent
  def initialize(saved_jobs:, status:, query:)
    @saved_jobs, @status, @query = saved_jobs, status, query
  end

  def filtered?
    @status != "all" || @query.present?
  end

  def visible_job?(job)
    job.is_active? && job.published?
  end
end
