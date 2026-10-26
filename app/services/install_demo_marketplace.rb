require Rails.root.join("db/seed_engine")

# Only bootstraps an explicitly enabled, isolated demo. Subsequent deploys leave
# the owner's credentials and every visitor's edits intact.
class InstallDemoMarketplace
  OWNER_EMAIL = "owner@crewbase-demo.example"
  CREW = [
    [ "Alex", "Rivera", "Audio Engineer" ],
    [ "Morgan", "Brooks", "Lighting Technician" ],
    [ "Jordan", "Lee", "Camera Operator" ],
    [ "Casey", "Taylor", "Stage Manager" ],
    [ "Avery", "Reed", "Video Engineer" ],
    [ "Sam", "Parker", "Production Manager" ]
  ].freeze

  def initialize(enabled:, owner_password:)
    @enabled = enabled
    @owner_password = owner_password
  end

  def call
    raise ArgumentError, "Demo setup requires CREWBASE_DEMO=true" unless @enabled
    raise ArgumentError, "DEMO_OWNER_PASSWORD must contain at least 16 characters" if @owner_password.to_s.length < 16

    User.transaction do
      # Render can overlap a new release with the previous release at startup.
      User.connection.execute("SELECT pg_advisory_xact_lock(10626001)")
      existing = User.find_by(email: OWNER_EMAIL)
      next existing if existing

      install_catalogs
      owner = create_member("Demo", "Owner", OWNER_EMAIL, @owner_password, "Production Manager")
      owner.roles << Role.find_by!(name: "app_owner")
      CREW.each_with_index do |(first, last, occupation), index|
        create_member(first, last, "crew-#{index + 1}@crewbase-demo.example", SecureRandom.hex(24), occupation)
      end
      create_company_and_jobs(owner)
      owner
    end
  end

  private

  def install_catalogs
    engine = SeedEngine.new
    engine.create_roles
    engine.create_occupations
    engine.create_plans unless Plan.exists?(key: "team_2026")
  end

  def create_member(first, last, email, password, occupation_name)
    user = User.create!(first_name: first, last_name: last, email: email, password: password)
    user.roles << Role.find_by!(name: "user")
    profile = user.profiles.create!(profile_type: "user", headline: occupation_name,
      bio: "Fictional demo profile for exploring KnowShow's staffing and recommendation tools.", completed_at: Time.current)
    profile.occupations << Occupation.find_by!(name: occupation_name, category_key: nil)
    profile.locations.create!(city: "Chicago", state: "IL", country: "United States")
    user
  end

  def create_company_and_jobs(owner)
    industry = Industry.music_touring!
    company = Company.create!(name: "Demo Live Productions", contact_email: "team@crewbase-demo.example",
      industries: [ industry ], is_public: true,
      description: "A fictional live music touring company. These sample jobs are for trying KnowShow, not real openings.")
    company.company_plans.create!(plan: Plan.find_by!(key: "team_2026"), status: "active")
    company.company_assignments.create!(user: owner, profile: owner.user_profile, role: "owner")
    company.locations.create!(city: "Chicago", state: "IL", country: "United States")

    [ "Audio Engineer", "Lighting Technician", "Camera Operator" ].each_with_index do |name, index|
      start = (index + 2).weeks.from_now.change(hour: 9)
      job = company.jobs.create!(title: "Demo event — #{name}", description: "Sample opening for a fictional live event. Explore matching, applications, invitations, and crew conversations here.",
        workplace_type: :on_site, employment_type: :contract, posting_type: :single_role,
        pay_min: 400, pay_max: 600, pay_period: :daily, is_active: true,
        status: :published, published_at: Time.current, starts_at: start, ends_at: start + 10.hours,
        application_deadline: start - 1.day, created_by: owner.id, editable_by_company: true)
      job.locations.create!(city: "Chicago", state: "IL", country: "United States")
      job.job_requirements.create!(requirement: Occupation.find_by!(name: name, category_key: nil),
        importance: :required, source: :employer, confirmed_at: Time.current)
    end
  end
end
