require "test_helper"

class RecommendationBookingQueriesTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    @owner = make_user("owner")
    @workers = 3.times.map { |index| make_user("worker-#{index}") }
    @company = Company.create!(name: "Batch Bookings", contact_email: "batch-bookings@example.com", industries: [ Industry.create!(name: "Batch Bookings") ])
    @company.company_assignments.create!(user: @owner, role: "owner")
    @jobs = (5..8).map { |day| make_job("Candidate #{day}", day) }
    booked = make_job("Agreed terms", 15)
    application = booked.job_applications.create!(profile: @workers[0].user_profile, status: :accepted)
    application.job_offers.create!(profile: @workers[0].user_profile, sender: @owner, role: "Audio", status: :accepted,
      starts_at: @jobs[0].starts_at, ends_at: @jobs[0].ends_at, rate: 300, currency: "USD", pay_unit: "daily")
    make_job("Legacy application", 6).job_applications.create!(profile: @workers[1].user_profile, status: :accepted)
    crew_job = make_job("Legacy crew", 7)
    crew_job.update!(posting_type: :multi_position)
    crew_job.crew_positions.create!(title: "Audio", headcount: 1).crew_assignments.create!(profile: @workers[2].user_profile)
  end

  test "crew matching loads booked schedules once across profiles and jobs while retaining conflict explanations" do
    recommender = CrewRecommender.new(user: @owner, jobs: @jobs, limit: nil)
    matches = {}
    query_count = booking_query_count do
      @jobs.each { |job| matches[job.id] = recommender.results_for(job) }
    end
    @workers.each_with_index do |worker, index|
      result = matches.fetch(@jobs[index].id).find { |match| match.profile.user_id == worker.id }
      assert_equal :near, result.tier
      assert_match(/Unavailable/, result.availability_label)
      assert_equal :full, matches.fetch(@jobs.last.id).find { |match| match.profile.user_id == worker.id }.tier
    end
    assert_operator query_count, :<=, 3, "Booking queries must be bounded across all profile/job pairs"
  end

  test "worker recommendations reuse schedules and honor offer dates instead of legacy job dates" do
    result = nil
    query_count = booking_query_count do
      result = WorkerJobRecommender.new(profile: @workers.first.user_profile, jobs: @jobs, limit: nil).results
    end
    assert_equal @jobs.drop(1).map(&:id).sort, result.map { |match| match.job.id }.sort
    assert_operator query_count, :<=, 3, "Booking queries must not grow with candidate jobs"
  end

  private

  def booking_query_count
    queries = []
    subscriber = ->(_name, _start, _finish, _id, payload) do
      next if payload[:name] == "SCHEMA" || payload[:cached]
      queries << payload[:sql] if payload[:sql].match?(/\ASELECT/) && payload[:sql].match?(/"(?:job_offers|job_applications|crew_assignments)"/)
    end
    ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") { yield }
    queries.size
  end

  def make_user(label)
    user = User.create!(first_name: label, last_name: "Booking Queries", email: "booking-query-#{label}@example.com", password: "password123")
    user.profiles.create!(profile_type: "user", completed_at: Time.current, capability_keys: [ "audio" ])
    user
  end

  def make_job(title, day)
    starts = day.days.from_now.change(hour: 12)
    @company.jobs.create!(title: title, description: "Audio work", status: :published, workplace_type: :on_site, employment_type: :contract,
      starts_at: starts, ends_at: starts + 2.hours, required_capability_keys: [ "audio" ])
  end
end
