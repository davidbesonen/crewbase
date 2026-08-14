class Admin::JobsQuery
  def initialize(params:)
    @params = params
  end

  def results
    scope = Job.includes(:company, :job_applications).order(created_at: :desc, id: :desc)
    scope = scope.where(status: params[:status]) if Job.statuses.key?(params[:status])
    params[:q].present? ? scope.where("jobs.title ILIKE ?", "%#{Job.sanitize_sql_like(params[:q])}%") : scope
  end

  private

  attr_reader :params
end
