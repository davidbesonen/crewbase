require "test_helper"

class Usr::SavedJobsComponentTest < ViewComponent::TestCase
  test "unavailable saved job explains its state and can be removed" do
    job = Job.new(id: 10, title: "Closed audio role", status: :closed, company: Company.new(name: "Tour company"))
    saved = SavedJob.new(job:, created_at: Time.current)
    render_inline(Usr::SavedJobsComponent.new(saved_jobs: [ saved ], status: "unavailable", query: ""))
    assert_text "No longer accepting applications"
    assert_no_selector "a[href='/usr/jobs/10']"
    assert_selector "button[aria-label='Remove Closed audio role from saved jobs']"
    assert_selector "a", text: "Reset"
  end
end
