require "test_helper"

class Marketing::ConcertSceneComponentTest < ViewComponent::TestCase
  test "provides responsive artwork with a useful description and a progressively enhanced motion control" do
    render_inline Marketing::ConcertSceneComponent.new

    assert_selector "figure.concert-scene[data-controller='concert-scene']"
    assert_selector "img[alt*='lead singer'][alt*='saxophonist'][width][height][srcset][fetchpriority='high']"
    assert_selector "button[hidden][type='button']", visible: :all, text: "Pause animation"
    assert_no_selector "canvas"
  end
end
