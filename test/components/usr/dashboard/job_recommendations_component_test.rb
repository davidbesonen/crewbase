require "test_helper"

class Usr::Dashboard::JobRecommendationsComponentTest < ViewComponent::TestCase
  Result = Data.define(:job, :match_reasons, :availability_label, :score, :matched_terms)
  JobRecord = Data.define(:id, :title, :company, :formatted_location, :compensation_range, :pay_period, :relative_published_at)
  CompanyRecord = Data.define(:id, :name)

  test "renders recommended jobs with transparent match reasons" do
    company = CompanyRecord.new(id: 7, name: "Touring Co")
    job = JobRecord.new(
      id: 12,
      title: "Lighting Technician",
      company:,
      formatted_location: "Chicago, IL",
      compensation_range: "$500.00 - $700.00",
      pay_period: "daily",
      relative_published_at: "2 days ago"
    )
    result = Result.new(
      job:,
      match_reasons: [ "Matches Lighting Technician and GrandMA3", "Located in Chicago, IL", "Available for job dates" ],
      availability_label: "Available for job dates",
      score: 20,
      matched_terms: [ "Lighting Technician", "GrandMA3" ]
    )

    render_inline(Usr::Dashboard::JobRecommendationsComponent.new(
      results: [ result ],
      applied_job_ids: Set.new,
      jobs_path: "/usr/jobs"
    ))

    assert_selector "[data-worker-job-recommendation]", count: 1
    assert_selector "a[href='/usr/jobs/12']", text: "Lighting Technician"
    assert_text "Matches Lighting Technician and GrandMA3"
    assert_text "Located in Chicago, IL"
    assert_text "Available for job dates"
    assert_selector "a[href='/usr/jobs']", text: "View More Jobs"
  end

  test "marks jobs the worker already applied to" do
    company = CompanyRecord.new(id: 7, name: "Touring Co")
    job = JobRecord.new(
      id: 12,
      title: "Lighting Technician",
      company:,
      formatted_location: "Remote",
      compensation_range: nil,
      pay_period: nil,
      relative_published_at: "1 day ago"
    )
    result = Result.new(
      job:,
      match_reasons: [ "Matches Lighting Technician" ],
      availability_label: "Availability not confirmed",
      score: 10,
      matched_terms: [ "Lighting Technician" ]
    )

    render_inline(Usr::Dashboard::JobRecommendationsComponent.new(
      results: [ result ],
      applied_job_ids: Set[12],
      jobs_path: "/usr/jobs"
    ))

    assert_selector ".badge", text: "Applied"
  end

  test "renders a useful empty state" do
    render_inline(Usr::Dashboard::JobRecommendationsComponent.new(
      results: [],
      applied_job_ids: Set.new,
      jobs_path: "/usr/jobs"
    ))

    assert_text "Add occupations, skills, or equipment to your profile"
    assert_selector "a[href='/usr/jobs']", text: "Browse all jobs"
  end
end
