require "test_helper"

class Usr::CalendarEventsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @user = User.create!(
      first_name: "Calendar",
      last_name: "Owner",
      email: "calendar-owner@example.com",
      password: "password123"
    )
    @profile = @user.profiles.create!(profile_type: "user", completed_at: Time.current)
    @other_profile = User.create!(
      first_name: "Other",
      last_name: "Person",
      email: "other-calendar@example.com",
      password: "password123"
    ).profiles.create!(profile_type: "user", completed_at: Time.current)
    sign_in @user, scope: :user
  end

  test "toggle cannot add an event to another users profile" do
    assert_no_difference "CalendarEvent.count" do
      get toggle_date_selection_usr_profile_calendar_events_path(@other_profile),
        params: { date: "07/25/2026", month: "2026-07-01", toggle_action: "add" },
        as: :turbo_stream
    end

    assert_response :not_found
  end

  test "toggle cannot remove another users calendar event" do
    event = @other_profile.calendar_events.create!(
      provider: "manual",
      external_id: "7/25/2026",
      to_date: Time.zone.local(2026, 7, 25),
      event_type: "blockout"
    )

    assert_no_difference "CalendarEvent.count" do
      get toggle_date_selection_usr_profile_calendar_events_path(@profile),
        params: {
          date: "2026-07-25",
          month: "2026-07-01",
          toggle_action: "remove",
          calendar_event_id: event.id
        },
        as: :turbo_stream
    end

    assert_response :not_found
  end

  test "toggle rejects an invalid date instead of raising" do
    assert_no_difference "CalendarEvent.count" do
      get toggle_date_selection_usr_profile_calendar_events_path(@profile),
        params: { date: "not-a-date", month: "2026-07-01", toggle_action: "add" },
        as: :turbo_stream
    end

    assert_response :unprocessable_entity
  end

  test "JSON calendar endpoints accept the ISO dates sent by the calendar controller" do
    assert_difference "CalendarEvent.count", 1 do
      post usr_profile_calendar_events_path(@profile),
        params: { date: "2026-07-26" },
        as: :json
    end
    assert_response :success

    assert_difference "CalendarEvent.count", -1 do
      delete usr_profile_calendar_event_path(@profile, "2026-07-26"), as: :json
    end
    assert_response :success
  end
end
