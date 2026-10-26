require "test_helper"

class WorkedTogetherTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    @profiles = %w[one two three].map do |name|
      User.create!(first_name: name, last_name: "Crew", email: "worked-#{name}@example.com", password: "password123").profiles.create!(profile_type: "user", completed_at: Time.current)
    end
    company = Company.create!(name: "Shared Crew", contact_email: "shared@example.com", industries: [ Industry.create!(name: "Shared Events") ])
    @job = company.jobs.create!(title: "Completed festival", employment_type: :contract, workplace_type: :on_site, description: "Festival", starts_at: 3.days.ago, ends_at: 2.days.ago, status: :completed)
    @profiles.first(2).each do |profile|
      profile.credits.create!(job: @job, role: "Lighting", project_name: @job.title, verified_at: Time.current, starts_on: 3.days.ago.to_date, ends_on: 2.days.ago.to_date)
    end
  end

  test "returns recorded coworkers once with shared credits without connecting them" do
    rows = WorkedTogether.new(user: @profiles.first.user).results
    assert_equal [ @profiles.second.id ], rows.map { |row| row.profile.id }
    assert_equal [ @job.id ], rows.first.credits.map(&:job_id)
    assert_equal 0, NetworkConnection.count
    assert_empty WorkedTogether.new(user: @profiles.third.user).results
  end

  test "respects hidden credit and profile settings" do
    @profiles.second.credits.first.update!(visible: false)
    assert_empty WorkedTogether.new(user: @profiles.first.user).results
    @profiles.second.credits.first.update!(visible: true)
    @profiles.second.update!(show_credits: false)
    assert_empty WorkedTogether.new(user: @profiles.first.user).results
  end

  test "does not imply shared work for uncompleted gigs or unverified credits" do
    @job.update!(status: :filled)
    assert_empty WorkedTogether.new(user: @profiles.first.user).results
    @job.update!(status: :completed)
    @profiles.second.credits.first.update!(verified_at: nil)
    assert_empty WorkedTogether.new(user: @profiles.first.user).results
  end

  test "does not include nonoverlapping dates on a shared gig" do
    @profiles.second.credits.first.update!(starts_on: 10.days.ago.to_date, ends_on: 9.days.ago.to_date)
    assert_empty WorkedTogether.new(user: @profiles.first.user).results
  end
end
