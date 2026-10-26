class SavedJobCollection
  attr_reader :status, :query

  def initialize(user:, status: nil, query: nil)
    @user = user
    @status = %w[open unavailable].include?(status) ? status : "all"
    @query = query.to_s.strip.first(100)
  end

  def results
    scope = @user.saved_jobs.joins(job: :company)
    scope = scope.where(job_id: Job.accepting_applications.select(:id)) if status == "open"
    scope = scope.where.not(job_id: Job.accepting_applications.select(:id)) if status == "unavailable"
    if query.present?
      pattern = "%#{SavedJob.sanitize_sql_like(query)}%"
      scope = scope.where("jobs.title ILIKE :q OR companies.name ILIKE :q", q: pattern)
    end
    scope.includes(job: [ :locations, :company ]).order(created_at: :desc, id: :desc)
  end
end
