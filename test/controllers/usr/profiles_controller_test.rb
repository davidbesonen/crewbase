require "test_helper"

class Usr::ProfilesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @user = User.create!(
      first_name: "Profile",
      last_name: "Tester",
      email: "profiles-controller@example.com",
      password: "password123"
    )
    @user.profiles.create!(profile_type: "user", completed_at: Time.current)
    @user.visits.create!
  end

  test "updating a calendar feed queues synchronization" do
    sign_in @user, scope: :user
    profile = @user.user_profile

    assert_enqueued_with(job: FetchIcalFeedJob, args: [ profile.id ]) do
      patch update_calendar_usr_profile_path(profile), params: {
        profile: { ical_feed_url: "https://calendar.google.com/calendar/ical/private/basic.ics" }
      }, as: :turbo_stream
    end

    assert_response :success
    assert_nil profile.reload.ical_last_synced_at
  end

  test "index shows profiles and filters by name" do
    sign_in @user, scope: :user

    matching_user = User.create!(
      first_name: "Alex",
      last_name: "Morgan",
      email: "alex.morgan@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    Profile.create!(
      user: matching_user,
      profile_type: "user",
      headline: "Production Manager"
    )

    other_user = User.create!(
      first_name: "Jordan",
      last_name: "Lee",
      email: "jordan.lee@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    Profile.create!(
      user: other_user,
      profile_type: "user",
      headline: "Lighting Designer"
    )

    get usr_profiles_path, params: { q: { user_first_name_or_user_last_name_cont: "Alex" } }

    assert_response :success
    assert_includes response.body, matching_user.full_name
    assert_not_includes response.body, other_user.full_name
    assert_select ".card-accent.card-accent-cyan", minimum: 1
  end

  test "recommended index shows ranked people and a link to the full directory" do
    sign_in @user, scope: :user
    industry = Industry.create!(name: "Recommended People")
    company = Company.create!(
      name: "Recommendation Company",
      contact_email: "recommendations@example.com",
      industries: [ industry ]
    )
    company.company_assignments.create!(user: @user, role: "owner")
    company.jobs.create!(
      title: "Lighting Technician",
      description: "Build and operate lighting systems.",
      workplace_type: :on_site,
      employment_type: :contract,
      status: :published,
      is_active: true,
      published_at: Time.current,
      starts_at: 2.weeks.from_now
    )
    occupation = Occupation.create!(name: "Lighting Technician")
    recommended_user = User.create!(
      first_name: "Recommended",
      last_name: "Person",
      email: "recommended-person@example.com",
      password: "password123"
    )
    recommended_profile = recommended_user.profiles.create!(profile_type: "user", completed_at: Time.current)
    recommended_profile.occupations << occupation
    unrelated_user = User.create!(
      first_name: "Unrelated",
      last_name: "Person",
      email: "unrelated-person@example.com",
      password: "password123"
    )
    unrelated_user.profiles.create!(profile_type: "user", completed_at: Time.current)

    get usr_profiles_path, params: { recommended: "1" }

    assert_response :success
    assert_select "h1", text: "Recommended People"
    assert_select "h1 .bi-stars", count: 1
    assert_includes response.body, recommended_user.full_name
    assert_not_includes response.body, unrelated_user.full_name
    assert_select "a[href='#{usr_profiles_path}']", text: "Show all people"
    assert_select "input[type='checkbox'][name='recommended'][value='1'][checked]:not([disabled])"
    assert_select "[data-recommended-filter-help]", text: /matched to your company’s active jobs/
  end

  test "normal index disables recommended filter without an owned company" do
    sign_in @user, scope: :user

    get usr_profiles_path

    assert_response :success
    assert_select "h1", text: "People"
    assert_select "a", text: "Show all people", count: 0
    assert_select "input[type='checkbox'][name='recommended'][value='1'][disabled]"
    assert_select "[data-recommended-filter-help]", text: /available when your company has an open job/i
  end

  test "normal index disables recommended filter when owned companies have no open jobs" do
    sign_in @user, scope: :user
    industry = Industry.create!(name: "No Open Recommendation Jobs")
    company = Company.create!(
      name: "No Open Jobs Company",
      contact_email: "no-open-jobs@example.com",
      industries: [ industry ]
    )
    company.company_assignments.create!(user: @user, role: "owner")

    get usr_profiles_path

    assert_response :success
    assert_select "input[type='checkbox'][name='recommended'][value='1'][disabled]"
  end

  test "normal index enables recommended filter when an owned company has an open job" do
    sign_in @user, scope: :user
    industry = Industry.create!(name: "Open Recommendation Jobs")
    company = Company.create!(
      name: "Open Jobs Company",
      contact_email: "open-jobs@example.com",
      industries: [ industry ]
    )
    company.company_assignments.create!(user: @user, role: "owner")
    company.jobs.create!(
      title: "Open Recommendation Job",
      description: "An active job for recommendations.",
      workplace_type: :remote,
      employment_type: :contract,
      status: :published,
      is_active: true,
      published_at: Time.current
    )

    get usr_profiles_path

    assert_response :success
    assert_select "input[type='checkbox'][name='recommended'][value='1']:not([checked]):not([disabled])"
  end

  test "toggle occupation selection turbo stream keeps completed profile card spacing classes" do
    template = File.read(Rails.root.join("app/views/usr/profiles/toggle_occupation_selection.turbo_stream.haml"))

    assert_includes template, '.card.border-0.shadow-sm.mb-4{ id: "occupation_form" }'
  end
end
