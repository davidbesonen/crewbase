require "test_helper"
require Rails.root.join("db/seed_engine")

class SeedEngineTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    @engine = SeedEngine.new
    @engine.create_roles
  end

  test "creates the Google OAuth David Besonen account idempotently" do
    @engine.create_gmail_owner
    @engine.create_gmail_owner

    user = User.find_by!(email: "david.besonen139@gmail.com")
    assert_equal 1, User.where(email: user.email).count
    assert_equal "David", user.first_name
    assert_equal "Besonen", user.last_name
    assert_equal "google_oauth2", user.provider
    assert_equal "117627202751255199802", user.uid
    assert user.has_role?("user")
    assert user.has_role?("app_owner")
    assert_equal "user", user.user_profile.profile_type
  end

  test "reset removes notifications before their referenced users" do
    actor = User.create!(
      first_name: "Seed",
      last_name: "Actor",
      email: "seed-actor@example.com",
      password: "password123"
    )
    recipient = User.create!(
      first_name: "Seed",
      last_name: "Recipient",
      email: "seed-recipient@example.com",
      password: "password123"
    )
    Notification.create!(recipient:, actor:, kind: "seed_test", message: "Seed cleanup dependency")

    @engine.reset_mock_data

    assert_not User.exists?(id: recipient.id)
    assert_not User.exists?(id: actor.id)
    assert_not Notification.exists?
  end

  test "seeds occupations without expanding skill and equipment catalogs" do
    counts = [ Skill.count, Equipment.count ]
    @engine.create_industries
    @engine.create_occupations
    @engine.create_equipment
    @engine.create_skills
    assert_equal counts, [ Skill.count, Equipment.count ]
    assert Occupation.exists?(name: "Audio Engineer", category_key: nil)
    assert Occupation.exists?(name: "Camera Operator", category_key: nil)
    assert Industry.all.all? { |industry| industry.occupations.where(category_key: nil).any? }
  end

  test "creates two company-scoped launch plans without limiting company ownership" do
    @engine.create_plans

    assert_equal %w[free team_2026], Plan.active.pluck(:key)
    Plan.active.each do |plan|
      assert_equal "company", plan.data.fetch("billing_scope")
      assert_not plan.data.key?("companies_limit")
    end
  end

  test "does not seed paid crew memberships" do
    @engine.create_user_plans
    assert_empty UserPlan.active
  end

  test "mock companies exercise every beta pricing tier" do
    @engine.create_plans

    selected_keys = 6.times.map { |index| @engine.send(:seed_plan_for_company_index, index).key }

    assert_equal %w[team_2026 free team_2026 free team_2026 free], selected_keys
  end

  test "David Besonen Music is seeded on Team" do
    @engine.reset_mock_data
    @engine.create_industries
    @engine.create_occupations
    @engine.create_brands
    @engine.create_equipment
    @engine.create_skills
    @engine.create_plans
    @engine.create_roles
    @engine.create_mock_marketplace_data

    company = Company.find_by!(name: "David Besonen Music")

    assert_equal "team_2026", CompanyPlanEntitlement.new(company).tier
  end

  test "every seeded user has sent and received invitation history" do
    @engine.reset_mock_data
    @engine.create_industries
    @engine.create_occupations
    @engine.create_brands
    @engine.create_equipment
    @engine.create_skills
    @engine.create_plans
    @engine.create_roles
    @engine.create_mock_marketplace_data

    User.find_each do |user|
      assert JobInvitation.received_by(user).exists?, "Expected #{user.email} to have a received invitation"
      assert user.sent_job_invitations.exists?, "Expected #{user.email} to have a sent invitation"
    end

    assert JobInvitation.pending.exists?
    assert JobInvitation.accepted.exists?
    assert JobInvitation.declined.exists?
  end

  test "creates project-based staffing scenarios with structured requirements and assigned crew" do
    @engine.reset_mock_data
    @engine.create_industries
    @engine.create_occupations
    @engine.create_brands
    @engine.create_equipment
    @engine.create_skills
    @engine.create_plans
    @engine.create_roles
    @engine.create_mock_marketplace_data

    assert Company.joins(:projects).distinct.exists?
    assert Job.where.not(project_id: nil).exists?
    assert Job.joins(:job_requirements).distinct.exists?
    assert JobRequirement.required.where(requirement_type: "Occupation").exists?
    assert Job.where.not(preferred_skills_text: [ nil, "" ]).exists?
    assert Profile.where.not(capability_keys: []).exists?
    assert Job.where.not(required_capability_keys: []).exists?
    assert Job.joins(crew_positions: :crew_assignments).distinct.exists?

    single_postings = Job.single_role
    gigs = Job.multi_position
    assert single_postings.exists?
    assert gigs.exists?
    assert single_postings.where(status: :published).all? { |job| job.title.include?(job.required_occupations.first.name) }
    assert single_postings.all? { |job| job.crew_positions.empty? }
    assert gigs.all? { |job| job.title.match?(/Crew Call|Production Crew/) }
    assert gigs.all? { |job| job.crew_positions.size > 1 }

    staffed_job = Job.joins(crew_positions: :crew_assignments).first
    assert staffed_job.multi_position?
    assert staffed_job.crew_assignments.all? do |assignment|
      assignment.profile.job_applications.accepted.exists?(job: staffed_job)
    end
  end

  test "creates completed one-off gig credits for crew profiles" do
    @engine.reset_mock_data
    @engine.create_industries
    @engine.create_occupations
    @engine.create_brands
    @engine.create_equipment
    @engine.create_skills
    @engine.create_plans
    @engine.create_roles
    @engine.create_mock_marketplace_data

    profile = User.find_by!(email: SeedEngine::GMAIL_OWNER.fetch(:email)).user_profile
    credits = profile.credits.order(:starts_on)

    assert_operator credits.size, :>=, 3
    assert credits.all? { |credit| credit.ends_on <= Date.current }
    assert credits.all? { |credit| credit.job&.completed? }
    assert credits.all?(&:verified?)
    assert credits.all?(&:visible?)
    assert credits.any? { |credit| credit.starts_on == credit.ends_on }
    assert_equal credits.size, profile.user.notifications.where(kind: "crewbase_credit_earned").count
    assert credits.all? do |credit|
      credit.job.job_applications.accepted.exists?(profile: profile)
    end
  end

  test "creates full and availability near-match crew recommendation scenarios" do
    @engine.reset_mock_data
    @engine.create_industries
    @engine.create_occupations
    @engine.create_brands
    @engine.create_equipment
    @engine.create_skills
    @engine.create_plans
    @engine.create_roles
    @engine.create_mock_marketplace_data

    Company.find_each do |company|
      job = company.jobs.published.where(is_active: true).order(:starts_at).first
      next unless job

      eligible_profiles = Profile.where(profile_type: "user").where.not(user: company.owner)
      exact_matches = eligible_profiles.select { |profile| matches_all_required_taxonomy?(profile, job) }
      conflict_counts = exact_matches.index_with do |profile|
        JobAvailability.new(job:).conflict_dates(events: profile.calendar_events).size
      end

      assert conflict_counts.value?(0), "Expected an available exact match for #{company.name} / #{job.title}"
      assert conflict_counts.values.any? { |count| count.in?(1..2) },
        "Expected a one- or two-date near match for #{company.name} / #{job.title}"
    end
  end

  private

  def matches_all_required_taxonomy?(profile, job)
    job.job_requirements.required.all? do |requirement|
      association = requirement.requirement_type.underscore.pluralize
      profile.public_send(association).include?(requirement.requirement)
    end
  end
end
