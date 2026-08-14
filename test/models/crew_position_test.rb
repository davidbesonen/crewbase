require "test_helper"

class CrewPositionTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "requires a title and a positive headcount" do
    position = CrewPosition.new(title: "", headcount: 0)

    position.validate

    assert_includes position.errors[:title], "can't be blank"
    assert_includes position.errors[:headcount], "must be greater than 0"
  end

  test "stores its own description and compensation" do
    position = build_position(
      headcount: 2,
      description: "Runs monitors and coordinates RF.",
      pay_min: 450,
      pay_max: 600,
      pay_period: :daily
    )

    assert_equal "Runs monitors and coordinates RF.", position.description
    assert_equal "$450.00 - $600.00", position.compensation_range
    assert position.daily?
  end

  test "rejects an invalid compensation range" do
    position = build_position(headcount: 1)
    position.assign_attributes(pay_min: 600, pay_max: 450)

    assert_not position.valid?
    assert_includes position.errors[:pay_max], "must be greater than or equal to pay min"
  end

  test "does not allow more assignments than its headcount" do
    position = build_position(headcount: 1)
    first_profile = create_user("first").user_profile
    second_profile = create_user("second").user_profile
    position.crew_assignments.create!(profile: first_profile)

    assignment = position.crew_assignments.build(profile: second_profile)

    assert_not assignment.valid?
    assert_includes assignment.errors[:crew_position], "is already fully staffed"
  end

  private

  def build_position(headcount:, **attributes)
    owner = create_user("owner")
    industry = Industry.create!(name: "Crew Position Industry")
    company = Company.create!(name: "Crew Position Company", contact_email: "crew-position@example.com", industries: [ industry ])
    company.company_assignments.create!(user: owner, role: "owner")
    job = company.jobs.create!(
      title: "Tour",
      employment_type: :contract,
      posting_type: :multi_position,
      workplace_type: :on_site,
      status: :published,
      is_active: true,
      starts_at: 2.days.from_now,
      ends_at: 5.days.from_now,
      description: "Build the touring crew."
    )
    job.crew_positions.create!({ title: "Lighting Technician", headcount: }.merge(attributes))
  end

  def create_user(label)
    user = User.create!(
      first_name: label.titleize,
      last_name: "Crew",
      email: "#{label}-crew-position@example.com",
      password: "password123"
    )
    user.profiles.create!(profile_type: "user", completed_at: Time.current)
    user.visits.create!
    user
  end
end
