require "test_helper"

class PersonalRequirementUpdateTest < ActiveSupport::TestCase
  test "new job requirements cannot reintroduce retired occupations through submitted ids" do
    job = jobs(:one)
    actor = Occupation.create!(name: "Actor")
    assert_raises ActiveRecord::RecordInvalid do
      JobRequirementsUpdater.new(job:, selections: { required_occupation_ids: [ actor.id ] }).call
    end
    assert_not_includes job.reload.required_occupations, actor
  end
  test "old requirement submissions remain effective after a job has personal entries" do
    job = jobs(:one)
    job.update!(company: companies(:one), description: "Production job", required_skills_text: "Old migrated entry")
    JobRequirementsUpdater.new(job: job, selections: { required_skill_ids: [ skills(:one).id ] }).call
    assert_equal [ skills(:one).name ], JobExperienceRequirements.new(job.reload).names_for(:required_skills_text)
  end

  test "updating occupations preserves existing skill and equipment requirements" do
    job = jobs(:one)
    job.job_requirements.create!(requirement: skills(:one), importance: :required)
    job.update!(company: companies(:one), description: "An audio production role", required_skills_text: "Pro Tools", preferred_equipment_text: "My console")
    JobRequirementsUpdater.new(job: job, selections: { required_occupation_ids: [ occupations(:one).id ] }).call
    assert_equal "Pro Tools", job.reload.required_skills_text
    assert_equal "My console", job.preferred_equipment_text
    assert_equal [ skills(:one) ], job.required_skills.to_a
  end
end
