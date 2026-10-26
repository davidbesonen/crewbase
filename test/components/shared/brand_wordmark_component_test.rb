require "test_helper"

class Shared::BrandWordmarkComponentTest < ViewComponent::TestCase
  test "renders an accessible lowercase wordmark for light and dark surfaces without another page heading" do
    render_inline Shared::BrandWordmarkComponent.new
    assert_selector "[aria-label='KnowShow']"
    assert_selector "img[src*='knowshow-signal-on-light']", visible: :all
    assert_selector "img[src*='knowshow-signal-on-dark']", visible: :all
    assert_no_selector "h1"
    assert_no_text "Crewbase"
  end

  test "unknown preview concepts fall back to the working wordmark" do
    render_inline Shared::BrandWordmarkComponent.new(concept: "not-a-logo")
    assert_selector "img[src*='knowshow-signal-on-light']", visible: :all
  end

  test "hybrid concepts have portable artwork on both surfaces" do
    %w[tempo momentum drive].each do |key|
      render_inline Shared::BrandWordmarkComponent.new(concept: key)
      %w[light dark].each do |surface|
        assert_selector "img[src*='knowshow-#{key}-on-#{surface}']", visible: :all
      end
    end
  end
end
