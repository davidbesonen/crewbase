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

  test "creates broad skills and equipment coverage for every occupation" do
    @engine.create_industries
    @engine.create_occupations
    @engine.create_brands
    @engine.create_equipment
    @engine.create_skills

    uncovered_skills = Occupation.left_joins(:skills).group(:id).having("COUNT(skills.id) < 5").pluck(:name)
    uncovered_equipment = Occupation.left_joins(:equipment).group(:id).having("COUNT(equipment.id) < 3").pluck(:name)

    assert_empty uncovered_skills, "Expected at least five skills for: #{uncovered_skills.to_sentence}"
    assert_empty uncovered_equipment, "Expected at least three equipment entries for: #{uncovered_equipment.to_sentence}"

    assert Skill.exists?(name: "Dante Audio Networking")
    assert Skill.exists?(name: "RF Coordination")
    assert Skill.exists?(name: "Entertainment Power Distribution")
    assert Skill.exists?(name: "SMPTE ST 2110")
    assert Skill.exists?(name: "Color Management")

    assert Equipment.exists?(name: "Avid VENUE S6L")
    assert Equipment.exists?(name: "DiGiCo Quantum Series")
    assert Equipment.exists?(name: "grandMA3")
    assert Equipment.exists?(name: "ETC Eos Family")
    assert Equipment.exists?(name: "ARRI ALEXA 35")
    assert Equipment.exists?(name: "Ross Carbonite")
  end

  test "creates every company-scoped beta plan without limiting company ownership" do
    @engine.create_plans

    assert_equal %w[starter team studio], Plan.active.pluck(:key)
    Plan.active.each do |plan|
      assert_equal "company", plan.data.fetch("billing_scope")
      assert_not plan.data.key?("companies_limit")
    end
  end

  test "creates the crew Pro catalog without embedding Stripe identifiers" do
    @engine.create_user_plans

    plan = UserPlan.find_by!(slug: "crew-pro")
    assert_equal "Crew Pro", plan.name
    assert_equal 599, plan.monthly_price_cents
    assert_equal 4_900, plan.annual_price_cents
    assert plan.active?
    assert_nil plan.stripe_monthly_price_id
    assert_nil plan.stripe_annual_price_id
  end

  test "mock companies exercise every beta pricing tier" do
    @engine.create_plans

    selected_keys = 6.times.map { |index| @engine.send(:seed_plan_for_company_index, index).key }

    assert_equal %w[starter team studio starter team studio], selected_keys
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

    assert_equal "team", CompanyPlanEntitlement.new(company).tier
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
    assert JobRequirement.preferred.where(requirement_type: "Skill").exists?
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
