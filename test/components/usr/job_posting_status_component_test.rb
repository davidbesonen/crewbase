require "test_helper"

class Usr::JobPostingStatusComponentTest < ViewComponent::TestCase
  test "open postings have an explicit filled action with context" do
    render_inline Usr::JobPostingStatusComponent.new(job: job(:published))
    assert_selector "form.align-self-start[action='/usr/companies/12/jobs/34']"
    assert_selector "input[name='job[status]'][value='filled']", visible: :all
    assert_button "Mark as Filled"
    assert_text "Stops new applications"
    assert_no_button "Reopen Posting"
  end

  test "filled postings can be reopened" do
    render_inline Usr::JobPostingStatusComponent.new(job: job(:filled))
    assert_selector "input[name='job[status]'][value='published']", visible: :all
    assert_button "Reopen Posting"
    assert_no_button "Mark as Filled"
  end

  test "drafts and completed work do not offer staffing shortcuts" do
    [ :draft, :completed, :archived ].each do |status|
      render_inline Usr::JobPostingStatusComponent.new(job: job(status))
      assert_no_selector "form"
    end
  end

  private

  def job(status)
    Job.new(id: 34, company: Company.new(id: 12), status: status, is_active: true)
  end
end
