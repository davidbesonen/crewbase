require "test_helper"

class Marketing::HomepageComponentTest < ViewComponent::TestCase
  test "presents the product story and visitor call to action" do
    render_inline(
      Marketing::HomepageComponent.new(
        primary_cta_label: "Start staffing",
        primary_cta_path: "/users/sign_up",
        show_auth_links: true
      )
    ) { |homepage| homepage.with_brand { "KnowShow" } }

    assert_selector "main[data-marketing-homepage][data-controller~='marketing-motion']"
    assert_selector "[data-marketing-motion-target~='reveal']", minimum: 12
    assert_selector "[data-marketing-motion-stagger]", minimum: 6
    assert_selector "nav[aria-label='Primary navigation']"
    assert_selector "a[href='/users/sign_up']", text: "Start staffing", minimum: 2
    assert_selector "a[href='/users/sign_in']", text: /Sign in/
    assert_selector "h1", text: "Know Your Gigs. Own The Show.", normalize_ws: true
    assert_selector ".marketing-hero__lede", text: /Know who’s on your crew and where each gig stands/
    assert_selector ".marketing-footer__brand", text: "Know your gigs. Own the show."
    assert_selector "#how-it-works article", count: 3
    assert_selector "#how-it-works h3", text: "Confirm Bookings Together"
    assert_selector "#tour-staffing article", count: 4
    assert_selector "#tour-staffing", text: /start as Projects/
    assert_selector "#tour-staffing", text: /tentative until the worker accepts/
    assert_selector "#for-crew .marketing-feature", count: 3
    assert_selector "#for-crew h2", text: "Looking For Your Next Gig?"
    assert_selector "#for-companies .marketing-feature", count: 3
    assert_selector "#for-companies", text: /crew spreadsheet/
    assert_selector "#for-companies", text: /show brief/
    assert_selector "#pricing .marketing-price-card", count: 2
    assert_selector "#pricing", text: /Start Staffing Free/
    assert_selector "#pricing", text: /\$19/
    assert_no_text(/Founding Company|\$99|\$49/)
    assert_selector "#platform", text: /clear, job-relevant details/
    assert_selector "#platform", text: /Private crew connections/
    assert_no_text(/deterministic signals/)
    assert_no_text(/% match/)
  end
end
