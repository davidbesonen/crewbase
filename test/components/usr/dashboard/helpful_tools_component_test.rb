require "test_helper"

class Usr::Dashboard::HelpfulToolsComponentTest < ViewComponent::TestCase
  test "renders the most useful member destinations as icon links" do
    render_inline(
      Usr::Dashboard::HelpfulToolsComponent.new(
        jobs_path: "/usr/jobs",
        people_path: "/usr/profiles",
        saved_jobs_path: "/usr/saved_jobs",
        availability_path: "/usr/profiles/7/edit_calendar",
        profile_path: "/usr/profiles/7"
      )
    )

    assert_selector "nav[data-helpful-tools]" do
      assert_selector ".visually-hidden", text: "Helpful Tools"
      assert_selector "a", count: 5
      assert_selector "a[href='/usr/jobs']", text: "Find Jobs"
      assert_selector "a.dashboard-tool--primary", count: 1
      assert_selector "a.dashboard-tool--primary[href='/usr/jobs']", text: "Find Jobs"
      assert_selector "a[href='/usr/profiles']", text: "Find People"
      assert_selector "a[href='/usr/saved_jobs']", text: "Saved Jobs"
      assert_selector "a[href='/usr/profiles/7/edit_calendar']", text: "Availability"
      assert_selector "a[href='/usr/profiles/7']", text: "My Profile"
      assert_selector "a > i.bi", count: 5
      assert_selector "a > span", count: 5
    end
  end

  test "renders helpful tools without a surrounding card" do
    render_inline(
      Usr::Dashboard::HelpfulToolsComponent.new(
        jobs_path: "/usr/jobs",
        people_path: "/usr/profiles",
        saved_jobs_path: "/usr/saved_jobs",
        availability_path: "/usr/profile/calendar",
        profile_path: "/usr/profile"
      )
    )

    assert_selector ".card", count: 0
    assert_selector "a.dashboard-tool", count: 5
  end
end
