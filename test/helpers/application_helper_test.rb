require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "maps job lifecycle states to semantic color badges" do
    assert_respond_to self, :job_status_badge_class

    assert_equal "status-badge status-open", job_status_badge_class(:published)
    assert_equal "status-badge status-draft", job_status_badge_class(:draft)
    assert_equal "status-badge status-completed", job_status_badge_class(:completed)
    assert_equal "status-badge status-unavailable", job_status_badge_class(:closed)
  end
end
