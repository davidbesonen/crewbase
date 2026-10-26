require "test_helper"

class Usr::JobExperienceRequirementsComponentTest < ViewComponent::TestCase
  test "shows required and preferred entries to applicants and escapes their text" do
    job = Job.new(required_skills_text: "RF coordination", preferred_equipment_text: "<script>alert(1)</script>")
    render_inline Usr::JobExperienceRequirementsComponent.new(entries: JobExperienceRequirements.new(job).entries)
    assert_selector "[data-job-experience-requirements]", text: /Required Skills/
    assert_text "RF coordination"
    assert_text "Preferred Equipment"
    assert_no_selector "script"
  end

  test "distinguishes broad families from specific equipment requirements" do
    job = Job.new(required_equipment_family_keys: [ "audio_systems" ], required_equipment_text: "Yamaha CL5")
    render_inline Usr::JobExperienceRequirementsComponent.new(entries: JobExperienceRequirements.new(job).entries)
    assert_selector "h5", text: "Required Equipment Families"
    assert_selector "h5", text: "Required Equipment"
    assert_text "Audio systems"
    assert_text "Yamaha CL5"
  end
end
