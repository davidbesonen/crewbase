require "test_helper"

class DashboardQuickSearchTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "adds a filtered jobs link after individual results when several jobs match" do
    industry = Industry.create!(name: "Music")
    company = Company.create!(
      name: "Sound Stage",
      contact_email: "jobs@sound-stage.example",
      industries: [ industry ]
    )
    matching_jobs = [
      create_job(company:, title: "Music Producer"),
      create_job(company:, title: "Associate Music Producer")
    ]

    results = DashboardQuickSearch.new("Music Producer").results
    individual_results = results.select { |result| matching_jobs.map(&:title).include?(result.fetch(:label)) }
    view_jobs_result = results.find { |result| result[:type] == "job_collection" }

    assert_equal 2, individual_results.size
    assert_equal(
      {
        type: "job_collection",
        label: "Music Producer — View jobs",
        meta: "2 matching jobs",
        url: Rails.application.routes.url_helpers.usr_jobs_path(q: { title_cont: "Music Producer" })
      },
      view_jobs_result
    )
    assert_operator results.index(view_jobs_result), :>, individual_results.map { |result| results.index(result) }.max
  end

  test "does not add a filtered jobs link for a single matching job" do
    industry = Industry.create!(name: "Music")
    company = Company.create!(
      name: "Solo Sound",
      contact_email: "jobs@solo-sound.example",
      industries: [ industry ]
    )
    create_job(company:, title: "Music Producer")
    create_job(company:, title: "Music Producer (Draft)", status: :draft)
    create_job(company:, title: "Music Producer (Closed)", is_active: false)

    results = DashboardQuickSearch.new("Music Producer").results

    assert_not results.any? { |result| result[:type] == "job_collection" }
  end

  private

  def create_job(company:, title:, status: :published, is_active: true)
    company.jobs.create!(
      title:,
      description: "Produce music for a live event.",
      workplace_type: :on_site,
      employment_type: :contract,
      status:,
      is_active:,
      published_at: status == :published ? Time.current : nil
    )
  end
end
