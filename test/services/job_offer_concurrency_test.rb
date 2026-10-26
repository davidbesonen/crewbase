require "test_helper"

class JobOfferConcurrencyTest < ActiveSupport::TestCase
  self.fixture_table_names = []
  self.use_transactional_tests = false

  test "concurrent acceptance confirms only one worker for a single role" do
    token = SecureRandom.hex(8)
    users = 3.times.map do |i|
      User.create!(first_name: "Concurrent", last_name: "#{i}", email: "offer-race-#{token}-#{i}@example.com", password: "password123").tap do |user|
        user.profiles.create!(profile_type: "user", completed_at: Time.current)
      end
    end
    industry = Industry.create!(name: "Offer concurrency #{token}")
    company = Company.create!(name: "Offer concurrency #{token}", contact_email: "race@example.com", industries: [ industry ])
    company.company_assignments.create!(user: users.first, role: "owner")
    job = company.jobs.create!(title: "Race role", description: "Film", status: :published, workplace_type: :on_site, employment_type: :contract)
    offers = users.drop(1).map do |user|
      application = job.job_applications.create!(profile: user.user_profile)
      IssueJobOffer.new(application:, sender: users.first, attributes: { role: "Camera", starts_at: 5.days.from_now, ends_at: 6.days.from_now, rate: 300, currency: "USD", pay_unit: "daily" }).call.offer
    end
    gate = Queue.new
    threads = offers.map do |offer|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          gate.pop
          fresh = JobOffer.find(offer.id)
          RespondToJobOffer.new(offer: fresh, user: fresh.profile.user, action: "accept").call
        end
      end
    end
    2.times { gate << true }
    results = threads.map(&:value)
    assert_equal 1, results.count(&:success?)
    assert_equal 1, job.job_applications.accepted.count
    assert_equal 1, JobOffer.where(id: offers.map(&:id)).accepted.count
  ensure
    threads&.each(&:join)
    NotificationDelivery.where(recipient: users).delete_all if users
    ProductEvent.where(user: users).delete_all if users
    company&.destroy!
    Notification.where(recipient: users).or(Notification.where(actor: users)).delete_all if users
    users&.each(&:destroy!)
    industry&.destroy!
  end
end
