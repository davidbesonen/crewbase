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

  test "retired occupations cannot be added through picker or profile parameters" do
    sign_in @user, scope: :user
    actor = Occupation.create!(name: "Actor")
    profile = @user.user_profile
    post toggle_occupation_selection_usr_profile_path(profile), params: { occupation_id: actor.id }, as: :turbo_stream
    assert_response :not_found
    sign_in @user, scope: :user
    patch usr_profile_path(profile), params: { source: "completed_profile", profile: { occupation_ids: [ actor.id ] } }
    assert_response :not_found
    assert_empty profile.reload.occupations
  end

  test "stores confirmed broad experience separately from personal details" do
    sign_in @user, scope: :user
    profile = @user.user_profile
    patch usr_profile_path(profile), params: { source: "completed_profile", profile: {
      capability_keys: [ "", "audio" ], equipment_family_keys: [ "audio_systems" ],
      skills_text: "Live sound mixing", equipment_text: "Yamaha CL5"
    } }
    assert_redirected_to usr_profile_path(profile)
    assert_equal [ "audio" ], profile.reload.attributes["capability_keys"]
    assert_equal [ "audio_systems" ], profile.attributes["equipment_family_keys"]
    assert_equal "Live sound mixing", profile.skills_text
    get usr_profile_path(profile)
    assert_select "#profile-about .bi-person-workspace", count: 1
    assert_select "#profile-about .bi-stars", count: 0
    assert_select "#profile-skills", text: /Audio production/
    assert_select "#profile-skills", text: /Audio systems/
    get edit_usr_profile_path(profile), params: { source: "completed_profile" }
    assert_select "input[name='profile[capability_keys][]'][value='audio'][checked]"
    assert_select "input[name='profile[equipment_family_keys][]'][value='audio_systems'][checked]"
  end

  test "occupation changes update only the picker and never replace unsaved experience fields" do
    sign_in @user, scope: :user
    profile = @user.user_profile
    profile.update!(capability_keys: [ "camera" ], skills_text: "Camera setup")
    occupation = Occupation.create!(name: "FOH Engineer")
    post toggle_occupation_selection_usr_profile_path(profile), params: { occupation_id: occupation.id, source: "completed_profile" }, as: :turbo_stream
    assert_response :success
    assert_select "turbo-stream[target='occupation_form']", count: 1
    assert_select "turbo-stream[target='skill_equipment_form']", count: 0
    assert_equal [ "camera" ], profile.reload.capability_keys
    assert_equal "Camera setup", profile.skills_text
    get edit_usr_profile_path(profile), params: { source: "completed_profile" }
    assert_select "[data-category-row][hidden] input[value='audio'][disabled]"
    assert_select "[data-category-core-summary]", text: /Front-of-house mixing/
    assert_select "[data-category-primary] input[value='camera'][checked]"
    assert_select "[data-category-other] input[value='lighting']"
  end

  test "suggestions based on details require confirmation and never save the submitted form" do
    sign_in @user, scope: :user
    profile = @user.user_profile
    patch usr_profile_path(profile), params: { source: "completed_profile", suggest_experience_categories: "1", profile: {
      skills_text: "Live sound mixing", equipment_text: "Digital mixing consoles", bio: "Unsaved bio"
    } }, as: :turbo_stream
    assert_response :success
    assert_select "turbo-stream[target='experience-category-suggestions']"
    assert_includes response.body, 'data-experience-category-key="foh_mixing"'
    assert_includes response.body, 'data-experience-category-key="mixing_consoles"'
    assert_empty profile.reload.capability_keys
    assert_nil profile.skills_text
    assert_nil profile.bio
  end

  test "unrecognized product names stay personal details without forced classification" do
    sign_in @user, scope: :user
    patch usr_profile_path(@user.user_profile), params: { suggest_experience_categories: "1", profile: {
      equipment_text: "UncataloguedWidget ZX999"
    } }, as: :turbo_stream
    assert_response :success
    assert_includes response.body, "Choose any relevant categories above"
    assert_not_includes response.body, "data-experience-category-key="
  end

  test "rejects unknown experience categories without creating new catalog records" do
    sign_in @user, scope: :user
    assert_no_difference [ "Skill.count", "Equipment.count" ] do
      patch usr_profile_path(@user.user_profile), params: { source: "completed_profile", profile: { capability_keys: [ "made_up_category" ] } }
    end
    assert_response :unprocessable_entity
  end

  test "saves personal entries without growing the global catalogs and shows them on the profile" do
    sign_in @user, scope: :user
    profile = @user.user_profile
    assert_no_difference [ "Skill.count", "Equipment.count" ] do
      patch usr_profile_path(profile), params: {
        source: "completed_profile", profile: { skills_text: "Uncommon workflow", equipment_text: "Custom console model" }
      }
    end
    assert_redirected_to usr_profile_path(profile)
    get usr_profile_path(profile)
    assert_select "#profile-skills", text: /Uncommon workflow/
    assert_select "#profile-skills", text: /Custom console model/
  end

  test "legacy selection submissions update the personal entries after migration" do
    sign_in @user, scope: :user
    profile = @user.user_profile
    skill = Skill.create!(name: "Legacy workflow")
    profile.update!(skills_text: "Old migrated entry")
    patch usr_profile_path(profile), params: { source: "completed_profile", profile: { skill_ids: [ skill.id ] } }
    assert_redirected_to usr_profile_path(profile)
    assert_equal [ skill.name ], profile.reload.reported_skills

    post toggle_skill_selection_usr_profile_path(profile), params: { skill_id: skill.id }, as: :turbo_stream
    assert_response :success
    assert_empty profile.reload.reported_skills
  end

  test "legacy directory filters use current entries after a member clears old selections" do
    sign_in @user, scope: :user
    profile = @user.user_profile
    skill = Skill.create!(name: "Retired experience")
    profile.skills << skill
    profile.update!(skills_text: "")
    get usr_profiles_path, params: { q: { skills_name_eq: skill.name } }
    assert_response :success
    assert_select "h4 a[href='#{usr_profile_path(profile)}']", count: 0
  end

  test "overlong experience examples are rejected without losing the saved text" do
    sign_in @user, scope: :user
    profile = @user.user_profile
    profile.update!(work_examples: "Original experience")
    patch usr_profile_path(profile), params: {
      source: "completed_profile", profile: { work_examples: "x" * 2001 }
    }
    assert_response :unprocessable_entity
    assert_equal "Original experience", profile.reload.work_examples
  end

  test "onboarding saves optional concrete examples and displays them as text" do
    sign_in @user, scope: :user
    profile = @user.user_profile
    get edit_usr_profile_path(profile), params: { current_page: "skill_equipment_form" }
    assert_select "textarea[name='profile[work_examples]']"

    patch usr_profile_path(profile), params: {
      source: "completed_profile", profile: { work_examples: "FOH mixing on regional tours; <script>alert(1)</script>" }
    }
    assert_redirected_to usr_profile_path(profile)
    assert_includes profile.reload.work_examples, "regional tours"
    get usr_profile_path(profile)
    assert_select "#profile-work-examples", text: /regional tours/
    assert_select "#profile-work-examples script", count: 0
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
      completed_at: Time.current,
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
      completed_at: Time.current,
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
