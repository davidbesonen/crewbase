require "test_helper"

class Marketing::HomepageComponentTest < ViewComponent::TestCase
  test "presents the product story and visitor call to action" do
    render_inline(
      Marketing::HomepageComponent.new(
        primary_cta_label: "Join Crewbase",
        primary_cta_path: "/users/sign_up",
        show_auth_links: true
      )
    ) { |homepage| homepage.with_brand { "Crewbase" } }

    assert_selector "main[data-marketing-homepage][data-controller~='marketing-motion']"
    assert_selector "[data-marketing-motion-target~='reveal']", minimum: 12
    assert_selector "[data-marketing-motion-target~='parallax']", minimum: 1
    assert_selector "[data-marketing-motion-stagger]", minimum: 6
    assert_selector "nav[aria-label='Primary navigation']"
    assert_selector "a[href='/users/sign_up']", text: "Join Crewbase", minimum: 2
    assert_selector "a[href='/users/sign_in']", text: /Sign in/
    assert_selector "#how-it-works article", count: 3
    assert_selector "#for-crew .marketing-feature", count: 3
    assert_selector "#for-crew h2", text: "Show what you can do. Find work that fits."
    assert_selector "#for-companies .marketing-feature", count: 3
    assert_selector "#pricing .marketing-price-card", count: 3
    assert_selector "#pricing", text: /Free forever for crew/
    assert_selector "#pricing", text: /Founding Compan/
    assert_selector "#platform", text: /clear, job-relevant details/
    assert_no_text(/deterministic signals/)
    assert_selector ".marketing-crew-reason", count: 3
    assert_no_text(/% match/)
  end
end
