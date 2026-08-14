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

    assert_selector ".card.h-100[data-helpful-tools]" do
      assert_selector "h2", text: "Helpful Tools"
      assert_selector "a", count: 5
      assert_selector "a[href='/usr/jobs']", text: "Find Jobs"
      assert_selector "a[href='/usr/profiles']", text: "Find People"
      assert_selector "a[href='/usr/saved_jobs']", text: "Saved Jobs"
      assert_selector "a[href='/usr/profiles/7/edit_calendar']", text: "Availability"
      assert_selector "a[href='/usr/profiles/7']", text: "My Profile"
      assert_selector "a > .icon-orb i.bi", count: 5
      assert_selector "a > .small.text-muted", count: 5
    end
  end

  test "uses compact color orbs and a restrained helpful-tools accent" do
    render_inline(
      Usr::Dashboard::HelpfulToolsComponent.new(
        jobs_path: "/usr/jobs",
        people_path: "/usr/profiles",
        saved_jobs_path: "/usr/saved_jobs",
        availability_path: "/usr/profile/calendar",
        profile_path: "/usr/profile"
      )
    )

    assert_selector "[data-helpful-tools].card-accent.card-accent-cyan"
    assert_selector ".icon-orb", count: 5
  end
end
