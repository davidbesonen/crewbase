require "test_helper"

class JobRequirementTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "accepts supported requirement types" do
    [ Occupation.new, Skill.new, Equipment.new ].each do |requirement|
      job_requirement = build_job_requirement(requirement:)

      assert job_requirement.valid?, job_requirement.errors.full_messages.to_sentence
    end
  end

  test "rejects unsupported requirement types" do
    job_requirement = build_job_requirement(requirement: Company.new)

    assert_not job_requirement.valid?
    assert_includes job_requirement.errors[:requirement_type], "is not included in the list"
  end

  test "defines required and preferred importance levels" do
    assert_equal({ "required" => 0, "preferred" => 1 }, JobRequirement.importances)
  end

  test "defines employer and ai suggested sources" do
    assert_equal({ "employer" => 0, "ai_suggested" => 1 }, JobRequirement.sources)
  end

  test "prevents duplicate requirements with the same importance" do
    job = persisted_job
    occupation = Occupation.create!(name: "Monitor Engineer")
    JobRequirement.create!(job:, requirement: occupation, importance: :required, source: :employer)
    duplicate = JobRequirement.new(job:, requirement: occupation, importance: :required, source: :employer)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:requirement_id], "has already been taken"
  end

  test "allows the same requirement at a different importance" do
    job = persisted_job
    occupation = Occupation.create!(name: "Monitor Engineer")
    JobRequirement.create!(job:, requirement: occupation, importance: :required, source: :employer)
    preferred = JobRequirement.new(job:, requirement: occupation, importance: :preferred, source: :employer)

    assert preferred.valid?, preferred.errors.full_messages.to_sentence
  end

  private

  def build_job_requirement(requirement:)
    JobRequirement.new(
      job: Job.new,
      requirement:,
      importance: :required,
      source: :employer
    )
  end

  def persisted_job
    industry = Industry.create!(name: "Live Events")
    company = Company.create!(
      name: "Signal Events",
      contact_email: "staffing@signal.example",
      industries: [ industry ]
    )
    Job.create!(
      company:,
      title: "Festival audio crew",
      workplace_type: :on_site,
      employment_type: :contract,
      description: "Staff the festival audio team."
    )
  end
end
