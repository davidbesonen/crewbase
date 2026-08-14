require "test_helper"

class Usr::ProfileAvailabilityComponentTest < ViewComponent::TestCase
  test "shows the availability summary and a direct management action" do
    render_inline(
      Usr::ProfileAvailabilityComponent.new(
        overview: {
          status: "Blockout dates added",
          blocked_days: 2,
          next_blockout_date: Date.new(2026, 8, 14)
        },
        availability_path: "/usr/profiles/7/edit_calendar"
      )
    )

    assert_selector "[data-profile-availability]" do
      assert_selector "h2", text: "Availability"
      assert_text "Blockout dates added"
      assert_text "2 blocked days"
      assert_text I18n.l(Date.new(2026, 8, 14), format: :long)
      assert_selector "a[href='/usr/profiles/7/edit_calendar']", text: "Manage Availability"
    end
  end
end
