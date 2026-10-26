require "test_helper"

class Marketing::ConcertSceneComponentTest < ViewComponent::TestCase
  test "provides a still responsive illustration without animation controls or a scene controller" do
    render_inline Marketing::ConcertSceneComponent.new

    assert_selector "figure.concert-scene"
    assert_selector "img[alt*='lead singer'][alt*='saxophonist'][width][height][srcset][fetchpriority='high']"
    assert_no_selector "button, [data-controller], [data-motion]", visible: :all
    assert_no_selector "canvas"
  end
end
