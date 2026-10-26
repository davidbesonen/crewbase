require "test_helper"

class Usr::JobOffer::InboxComponentTest < ViewComponent::TestCase
  test "empty inbox offers navigation and accessible search" do
    render_inline(Usr::JobOffer::InboxComponent.new(summaries: [], counts: JobOfferInbox::VIEWS.keys.index_with(0), view: "needs_reply", query: ""))
    assert_selector "nav[aria-label='Filter offers'] a[aria-current='page']", text: /Needs your reply/
    assert_selector "label[for='q']", text: "Search offers"
    assert_selector "input[type='hidden'][name='view'][value='needs_reply']", visible: :all
    assert_selector "h2", text: "No Offers Yet"
    assert_selector "a[href='/usr/jobs']", text: "Browse jobs"
  end

  test "pending offer shows terms and a clear review action" do
    user = User.new(id: 1, first_name: "Alex", last_name: "Crew")
    job = Job.new(company: Company.new(name: "Tour company"))
    offer = JobOffer.new(id: 2, profile: Profile.new(user:), job_application: JobApplication.new(job:), role: "Lighting designer",
      starts_at: 5.days.from_now, ends_at: 6.days.from_now, expires_at: 1.day.from_now, rate: 500, currency: "EUR", pay_unit: "daily")
    summary = JobOfferSummary.new(offer:, viewer_id: user.id)
    render_inline(Usr::JobOffer::InboxComponent.new(summaries: [ summary ], counts: JobOfferInbox::VIEWS.keys.index_with(1), view: "all", query: ""))
    assert_selector "[data-offer-id='2']", text: /EUR 500.00/
    assert_text "Reply due soon"
    assert_selector "a.btn-primary[href='/usr/job_offers/2']", text: "Review offer"
  end
end
