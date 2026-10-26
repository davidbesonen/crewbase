require "test_helper"

class Usr::Dashboard::UpcomingWorkComponentTest < ViewComponent::TestCase
  test "bookings and openings have separate headings lists and context" do
    company = Company.new(name: "Touring Company")
    booking = Job.new(id: 1, title: "Confirmed Lighting", company:, status: :published, is_active: true, starts_at: 2.days.ago, ends_at: 3.days.from_now)
    opening = Job.new(id: 2, title: "Open Lighting", company:, starts_at: 1.week.from_now)

    render_inline(Usr::Dashboard::UpcomingWorkComponent.new(booked_jobs: [ booking ], opportunities: [ opening ]))

    assert_selector "h5", text: "Booked Work"
    assert_selector "[data-booked-work] a[href='/usr/jobs/1']", text: "Confirmed Lighting"
    assert_selector "[data-booked-work]", text: /Started/
    assert_selector "h6", text: "Upcoming Opportunities"
    assert_selector "[data-upcoming-opportunities] a[href='/usr/jobs/2']", text: "Open Lighting"
    assert_text "Openings with upcoming start dates. These are not bookings."
    assert_no_selector "[data-upcoming-opportunities] a[href='/usr/jobs/1']"
  end

  test "nonpublic bookings show the work without linking to an inaccessible job page" do
    company = Company.new(name: "Touring Company")
    bookings = [
      Job.new(id: 3, title: "Filled Lighting", company:, status: :filled, is_active: true, starts_at: 1.week.from_now),
      Job.new(id: 4, title: "Inactive Lighting", company:, status: :published, is_active: false, starts_at: 1.week.from_now)
    ]

    render_inline(Usr::Dashboard::UpcomingWorkComponent.new(booked_jobs: bookings, opportunities: []))

    assert_selector "[data-booked-work]", text: "Filled Lighting"
    assert_selector "[data-booked-work]", text: "Inactive Lighting"
    assert_no_selector "[data-booked-work] a"
  end

  test "empty booked work explains how work appears with a relevant next action" do
    render_inline(Usr::Dashboard::UpcomingWorkComponent.new(booked_jobs: [], opportunities: []))

    assert_text "You have no booked work scheduled. Confirmed offers and existing bookings will appear here."
    assert_text "There are no upcoming openings right now."
    assert_selector "a[href='/usr/job_applications']", text: "View Applications & Invitations"
    assert_selector "a[href='/usr/jobs']", text: "Browse Jobs"
  end
end
