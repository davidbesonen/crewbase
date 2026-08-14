# frozen_string_literal: true

class DashboardQuickSearch
  include Rails.application.routes.url_helpers

  MIN_QUERY_LENGTH = 2
  MAX_QUERY_LENGTH = 80
  RESULTS_PER_TYPE = 4
  CACHE_TTL = 30.seconds

  def initialize(query)
    @query = query.to_s.squish.first(MAX_QUERY_LENGTH)
  end

  def results
    return [] if query.length < MIN_QUERY_LENGTH

    Rails.cache.fetch([ "dashboard-quick-search", query.downcase ], expires_in: CACHE_TTL) do
      company_results + job_results + person_results
    end
  end

  private

  attr_reader :query

  def pattern
    @pattern ||= "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
  end

  def company_results
    Company
      .where("name ILIKE ?", pattern)
      .order(Arel.sql("LOWER(name) ASC"))
      .limit(RESULTS_PER_TYPE)
      .pluck(:id, :name)
      .map do |id, name|
        { type: "company", label: name, meta: "Company", url: usr_company_path(id) }
      end
  end

  def job_results
    scope = Job
      .left_joins(:company)
      .where(is_active: true, status: :published)
      .where("jobs.title ILIKE ?", pattern)
      .order(Arel.sql("LOWER(jobs.title) ASC"))

    results = scope
      .limit(RESULTS_PER_TYPE)
      .pluck("jobs.id", "jobs.title", "companies.name")
      .map do |id, title, company_name|
        { type: "job", label: title, meta: company_name.presence || "Job", url: usr_job_path(id) }
      end

    matching_job_count = scope.count
    return results if matching_job_count < 2

    results << {
      type: "job_collection",
      label: "#{query} — View jobs",
      meta: "#{matching_job_count} matching jobs",
      url: usr_jobs_path(q: { title_cont: query })
    }
  end

  def person_results
    Profile
      .joins(:user)
      .where(profile_type: "user")
      .where(
        "COALESCE(users.first_name, '') || ' ' || COALESCE(users.last_name, '') ILIKE ?",
        pattern
      )
      .order(Arel.sql("LOWER(users.first_name) ASC, LOWER(users.last_name) ASC"))
      .limit(RESULTS_PER_TYPE)
      .pluck("profiles.id", "users.first_name", "users.last_name")
      .map do |id, first_name, last_name|
        {
          type: "person",
          label: [ first_name, last_name ].compact_blank.join(" "),
          meta: "Person",
          url: usr_profile_path(id)
        }
      end
  end
end
