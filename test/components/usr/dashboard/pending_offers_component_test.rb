require "test_helper"

class Usr::Dashboard::PendingOffersComponentTest < ViewComponent::TestCase
  test "offers awaiting a reply link directly to review" do
    job = Job.new(company: Company.new(name: "Tour company"))
    offer = JobOffer.new(id: 1, role: "Audio", starts_at: 2.days.from_now, job_application: JobApplication.new(job:))
    render_inline(Usr::Dashboard::PendingOffersComponent.new(offers: [ offer ], count: 4))
    assert_selector "a[href='/usr/job_offers/1']", text: "Review offer"
    assert_selector "a[href='/usr/job_offers?view=needs_reply']", text: "View all (4)"
  end

  test "no empty attention card appears when there are no offers" do
    render_inline(Usr::Dashboard::PendingOffersComponent.new(offers: [], count: 0))
    assert_no_selector "[data-offers-needing-reply]"
  end
end
