class Admin::DashboardQuery
  def initialize(date_range:)
    @date_range = date_range
  end

  def call
    {
      totals: totals,
      labels: dates.map(&:iso8601),
      sign_ins: daily_counts(Visit.all),
      new_users: daily_counts(User.all),
      new_companies: daily_counts(Company.all),
      new_jobs: daily_counts(Job.all),
      job_statuses: Job.group(:status).count.transform_keys { |status| Job.statuses.key(status)&.humanize || status.to_s }
    }
  end

  private

  attr_reader :date_range

  def dates
    @dates ||= date_range.to_a
  end

  def time_range
    date_range.first.beginning_of_day..date_range.last.end_of_day
  end

  def totals
    {
      users: User.count,
      companies: Company.count,
      jobs: Job.count,
      published_jobs: Job.published.count,
      applications: JobApplication.count,
      sign_ins: Visit.where(created_at: time_range).count
    }
  end

  def daily_counts(scope)
    counts = scope.where(created_at: time_range).group("DATE(created_at)").count
    dates.map { |date| counts.fetch(date, 0) }
  end
end
