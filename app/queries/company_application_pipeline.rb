class CompanyApplicationPipeline
  attr_reader :company, :status, :job_id, :project_id, :query

  def initialize(company:, filters: {})
    @company = company
    @status = normalized_status(filters[:status])
    @job_id = normalized_job_id(filters[:job_id])
    @project_id = normalized_project_id(filters[:project_id])
    @query = filters[:query].to_s.strip.presence
  end

  def results
    @results ||= begin
      scope = summary_scope
      scope = scope.where(status: status) if status
      scope = filter_by_applicant(scope) if query
      scope.order(created_at: :desc)
    end
  end

  def jobs
    @jobs ||= begin
      scope = company.jobs
      scope = scope.where(project_id:) if project_id
      scope.order(:title)
    end
  end

  def total_count
    @total_count ||= summary_scope.count
  end

  def stage_counts
    @stage_counts ||= JobApplication.review_pipeline_statuses
      .index_with { 0 }
      .merge(summary_scope.group(:status).count)
  end

  private

  def base_scope
    JobApplication
      .includes(:profile, { profile: :user }, job: [ :company, { crew_positions: :crew_assignments } ])
      .joins(:job)
      .where(jobs: { company_id: company.id })
  end

  def summary_scope
    scope = base_scope
    scope = scope.where(jobs: { project_id: project_id }) if project_id
    scope = scope.where(job_id:) if job_id
    scope
  end

  def normalized_status(value)
    value = value.to_s
    value if JobApplication.review_pipeline_statuses.include?(value)
  end

  def normalized_job_id(value)
    value = value.to_s
    return unless value.match?(/\A\d+\z/)
    return unless company.jobs.where(id: value).exists?

    value
  end

  def normalized_project_id(value)
    value = value.to_s
    return unless value.match?(/\A\d+\z/)
    return unless company.projects.where(id: value).exists?

    value
  end

  def filter_by_applicant(scope)
    term = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
    scope.joins(profile: :user).where(
      "users.first_name ILIKE :term OR users.last_name ILIKE :term OR " \
      "CONCAT(users.first_name, ' ', users.last_name) ILIKE :term",
      term: term
    )
  end
end
