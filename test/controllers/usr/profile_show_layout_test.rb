require "test_helper"

class Usr::ProfileShowLayoutTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  test "regular users cannot see reviews on their own or another profile" do
    viewer = create_profile_user("viewer-review-visibility@example.com")
    other = create_profile_user("other-review-visibility@example.com")
    reviewer = create_profile_user("reviewer-review-visibility@example.com")
    [ viewer.user_profile, other.user_profile ].each do |profile|
      profile.received_reviews.create!(
        profile: reviewer.user_profile,
        overall_rating: 4.5,
        body: "Private company-owner feedback."
      )
    end
    sign_in viewer, scope: :user

    [ viewer.user_profile, other.user_profile ].each do |profile|
      get usr_profile_path(profile)

      assert_response :success
      assert_select "#profile-reviews", count: 0
      assert_select "[data-profile-review-summary]", count: 0
      assert_select "*", text: /Private company-owner feedback/, count: 0
    end
  end

  test "company owners can see reviews on user profiles" do
    owner = create_profile_user("owner-review-visibility@example.com")
    subject = create_profile_user("subject-review-visibility@example.com")
    reviewer = create_profile_user("owner-view-reviewer@example.com")
    subject.user_profile.received_reviews.create!(
      profile: reviewer.user_profile,
      overall_rating: 4.5,
      body: "Visible to company owners."
    )
    industry = Industry.create!(name: "Review Visibility")
    company = Company.create!(
      name: "Review Visibility Company",
      contact_email: "review-visibility@example.com",
      industries: [ industry ]
    )
    company.company_assignments.create!(user: owner, role: "owner")
    sign_in owner, scope: :user

    get usr_profile_path(subject.user_profile)

    assert_response :success
    assert_select "[data-profile-review-summary]", text: /1 review/
    assert_select "#profile-reviews", text: /Visible to company owners/
  end

  test "company owners cannot see reviews on their own profile" do
    owner = create_profile_user("self-review-owner@example.com")
    reviewer = create_profile_user("self-review-reviewer@example.com")
    owner.user_profile.received_reviews.create!(
      profile: reviewer.user_profile,
      overall_rating: 4.5,
      body: "Feedback hidden from its subject."
    )
    industry = Industry.create!(name: "Self Review Visibility")
    company = Company.create!(
      name: "Self Review Visibility Company",
      contact_email: "self-review-visibility@example.com",
      industries: [ industry ]
    )
    company.company_assignments.create!(user: owner, role: "owner")
    sign_in owner, scope: :user

    get usr_profile_path(owner.user_profile)

    assert_response :success
    assert_select "#profile-reviews", count: 0
    assert_select "[data-profile-review-summary]", count: 0
    assert_select "*", text: /Feedback hidden from its subject/, count: 0
  end

  test "users can review and manage availability from their own profile" do
    user = create_profile_user("profile-availability@example.com")
    profile = user.user_profile
    profile.calendar_events.create!(
      event_type: "blockout",
      provider: "manual",
      external_id: "profile-availability",
      from_date: 2.weeks.from_now.to_date,
      to_date: 2.weeks.from_now.to_date
    )
    sign_in user, scope: :user

    get usr_profile_path(profile)

    assert_response :success
    assert_select "[data-profile-availability]" do
      assert_select "a[href='#{edit_calendar_usr_profile_path(profile)}']", text: "Manage Availability"
      assert_select "*", text: /1 blocked day/
    end
  end

  test "availability management is not shown on another user's profile" do
    viewer = create_profile_user("availability-viewer@example.com")
    other = create_profile_user("availability-other@example.com")
    sign_in viewer, scope: :user

    get usr_profile_path(other.user_profile)

    assert_response :success
    assert_select "[data-profile-availability]", count: 0
    assert_select "a[href='#{edit_calendar_usr_profile_path(other.user_profile)}']", count: 0
  end

  test "snapshot appears to the left of about on the profile show card" do
    user = User.create!(
      first_name: "David",
      last_name: "Profile",
      email: "david.profile-layout@example.com",
      password: "password123"
    )
    profile = user.profiles.create!(profile_type: "user", completed_at: Time.current)
    sign_in user, scope: :user

    get usr_profile_path(profile)

    assert_response :success
    assert_select "#profile-about > .card-body > .row" do
      assert_select "> .col-lg-4:first-child h5", text: "Snapshot"
      assert_select "> .col-lg-8:last-child h5", text: "About"
    end
    assert_select "#profile-experience h5", text: "Experience"
    assert_select "#profile-skills", text: /No skills listed yet/
    assert_select "#profile-skills", text: /No equipment or tools listed yet/
    assert_select "h5", text: "Additional Sections", count: 0
    assert_select "*", text: /Placeholder/, count: 0
    assert_select ".app-hero.app-hero-cyan", count: 1
    assert_select "#profile-about.card-accent.card-accent-cyan"
    assert_select "#profile-experience.card-accent.card-accent-sky"
    assert_select "#profile-experience a[aria-label='Add experience'][href='#{edit_usr_profile_path(profile, source: "completed_profile", add_experience: 1, anchor: "experience_form")}']" do
      assert_select ".bi-plus-lg"
    end
  end

  test "linked companies show their icon in the experience timeline" do
    user = User.create!(
      first_name: "David",
      last_name: "Timeline",
      email: "david.timeline-icon@example.com",
      password: "password123"
    )
    profile = user.profiles.create!(profile_type: "user", completed_at: Time.current)
    industry = Industry.create!(name: "Timeline Icons")
    company = Company.create!(
      name: "Iconic Productions",
      contact_email: "iconic@example.com",
      industries: [ industry ]
    )
    profile.experiences.create!(title: "Lighting Tech", company: company)
    sign_in user, scope: :user

    get usr_profile_path(profile)

    assert_response :success
    assert_select "#profile-experience [data-experience-company-icon] .avatar-toggle[style*='56px']", text: "I"
    assert_select "#profile-experience a[href='#{usr_company_path(company)}']", text: company.name
  end

  test "experience summaries render rich text with an expandable three-line preview" do
    user = User.create!(
      first_name: "David",
      last_name: "Summary",
      email: "david.timeline-summary@example.com",
      password: "password123"
    )
    profile = user.profiles.create!(profile_type: "user", completed_at: Time.current)
    experience = profile.experiences.create!(
      title: "Production Manager",
      company_name: "Independent",
      summary: "<div>Line one</div><div>Line two</div><div>Line three</div><div>Line four</div>"
    )
    sign_in user, scope: :user

    get usr_profile_path(profile)

    assert_response :success
    assert_select "[data-controller='expandable-text']" do
      assert_select "[data-expandable-text-target='content'].experience-summary-content"
      assert_select "button[data-action='expandable-text#toggle']", text: "…more"
    end
    assert_equal "Line one\nLine two\nLine three\nLine four", experience.reload.summary.to_plain_text
  end

  test "recent feedback cards have consistent internal padding" do
    user = User.create!(
      first_name: "David",
      last_name: "Reviewed",
      email: "david.feedback-spacing@example.com",
      password: "password123"
    )
    profile = user.profiles.create!(profile_type: "user", completed_at: Time.current)
    reviewer_user = User.create!(
      first_name: "Riley",
      last_name: "Reviewer",
      email: "riley.feedback-spacing@example.com",
      password: "password123"
    )
    reviewer_profile = reviewer_user.profiles.create!(profile_type: "user", completed_at: Time.current)
    profile.received_reviews.create!(
      profile: reviewer_profile,
      overall_rating: 4.5,
      body: "Great collaborator."
    )
    industry = Industry.create!(name: "Feedback Layout")
    company = Company.create!(
      name: "Feedback Layout Company",
      contact_email: "feedback-layout@example.com",
      industries: [ industry ]
    )
    company.company_assignments.create!(user: reviewer_user, role: "owner")
    sign_in reviewer_user, scope: :user

    get usr_profile_path(profile)

    assert_response :success
    assert_select "#profile-reviews .border.rounded-3.p-3", count: 1 do
      assert_select ".fw-semibold", text: reviewer_user.full_name
      assert_select "p", text: "Great collaborator."
    end
  end

  test "company owners see a useful empty state when a profile has no reviews" do
    owner = create_profile_user("empty-review-owner@example.com")
    subject = create_profile_user("empty-review-subject@example.com")
    industry = Industry.create!(name: "Empty Review Copy")
    company = Company.create!(
      name: "Empty Review Copy Company",
      contact_email: "empty-review-copy@example.com",
      industries: [ industry ]
    )
    company.company_assignments.create!(user: owner, role: "owner")
    sign_in owner, scope: :user

    get usr_profile_path(subject.user_profile)

    assert_response :success
    assert_select "#profile-reviews", text: /No written feedback yet/
    assert_select "#profile-reviews", text: /Placeholder/, count: 0
  end

  private

  def create_profile_user(email)
    User.create!(
      first_name: "Review",
      last_name: "Viewer",
      email:,
      password: "password123"
    ).tap do |user|
      user.profiles.create!(profile_type: "user", completed_at: Time.current)
    end
  end
end
