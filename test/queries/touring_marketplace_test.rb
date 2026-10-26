require "test_helper"

class TouringMarketplaceTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "discovery excludes companies and jobs explicitly outside music touring" do
    touring = Industry.create!(name: "Live Music & Touring")
    film = Industry.create!(name: "Film, TV & Commercial Production")
    company = Company.create!(name: "Tour", contact_email: "tour@example.com", industries: [ touring ])
    studio = Company.create!(name: "Film", contact_email: "film@example.com", industries: [ film ])
    jobs = [ company, studio ].map { |employer| employer.jobs.create!(title: "Crew", description: "Touring crew", employment_type: :contract, workplace_type: :on_site) }
    assert_equal [ company.id ], TouringMarketplace.companies(Company.where(id: [ company.id, studio.id ])).ids
    assert_equal [ jobs.first.id ], TouringMarketplace.jobs(Job.where(id: jobs.map(&:id))).ids
    assert Company.exists?(studio.id), "Historical records must not be deleted"
  end

  test "touring and crossover people remain discoverable but unrelated occupations do not" do
    role = Occupation.create!(name: "Lighting Technician")
    actor = Occupation.create!(name: "Actor")
    profiles = [ [ role ], [ actor ], [ actor, role ], [] ].each_with_index.map do |occupations, index|
      user = User.create!(first_name: "Crew", last_name: index.to_s, email: "touring-#{index}@example.com", password: "password123")
      user.profiles.create!(profile_type: "user", occupations:)
    end
    assert_equal profiles.values_at(0, 2, 3).map(&:id).sort, TouringMarketplace.profiles(Profile.where(id: profiles.map(&:id))).ids.sort
    assert_equal [ actor ], profiles[1].reload.occupations
  end

  test "a touring company cannot surface a historical job for a retired occupation" do
    company = Company.create!(name: "Tour history", contact_email: "tour-history@example.com", industries: [ Industry.music_touring! ])
    actor = Occupation.create!(name: "Actor")
    lighting = Occupation.find_or_create_by!(name: "Lighting Technician")
    jobs = [ actor, lighting ].map do |occupation|
      job = company.jobs.create!(title: occupation.name, description: "Historical job", employment_type: :contract, workplace_type: :on_site)
      job.job_requirements.create!(requirement: occupation, importance: :required)
      job
    end
    assert_equal [ jobs.last.id ], TouringMarketplace.jobs(Job.where(id: jobs.map(&:id))).ids
    assert Job.exists?(jobs.first.id)
  end
end
