require "test_helper"

class ConfirmedExperienceMigrationTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "migration carries forward active categories without reviving cleared selections" do
    assert File.exist?(Rails.root.join("db/catalogs/confirmed_experience_v1.rb")), "Migration needs a tested, versioned category backfill"
    require Rails.root.join("db/catalogs/confirmed_experience_v1")
    skill = Skill.create!(name: "Audio production", category_key: "audio")
    user = User.create!(first_name: "Migration", last_name: "Test", email: "category-migration@example.com", password: "password123")
    active = user.profiles.create!(profile_type: "user", skills: [ skill ], skills_text: skill.name)
    cleared = user.profiles.create!(profile_type: "company_owner", skills: [ skill ], skills_text: "")
    company = Company.create!(name: "Migration company", contact_email: "migration-company@example.com", industries: [ Industry.create!(name: "Migration industry") ])
    job = company.jobs.create!(title: "Audio job", description: "Audio work", employment_type: :contract, workplace_type: :on_site, required_skills_text: "")
    job.job_requirements.create!(requirement: skill, importance: :required)

    ConfirmedExperienceV1.install!
    assert_equal [ "audio" ], active.reload.capability_keys
    assert_empty cleared.reload.capability_keys
    assert_empty job.reload.required_capability_keys
    assert_equal "", cleared.skills_text
    assert_equal [ skill ], cleared.skills.to_a
    job.update!(required_skills_text: skill.name)
    active.update!(capability_keys: [ "lighting" ])
    ConfirmedExperienceV1.install!
    assert_equal [ "audio" ], job.reload.required_capability_keys
    assert_equal [ "lighting" ], active.reload.capability_keys
  end
end
