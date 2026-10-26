require "application_system_test_case"

class OfferCurrencyTest < ApplicationSystemTestCase
  include Warden::Test::Helpers
  self.fixture_table_names = []

  test "offer rate prefix follows currency edits and reloads without changing the amount" do
    owner = create_user("owner")
    worker = create_user("worker")
    industry = Industry.create!(name: "Currency test")
    company = Company.create!(name: "Currency test", contact_email: "currency@example.com", industries: [ industry ])
    company.company_assignments.create!(user: owner, role: "owner")
    job = company.jobs.create!(title: "Camera", description: "Film", status: :published,
      workplace_type: :on_site, employment_type: :contract, pay_min: 400,
      starts_at: 5.days.from_now, ends_at: 6.days.from_now)
    application = job.job_applications.create!(profile: worker.user_profile)
    login_as owner, scope: :user

    visit new_usr_job_offer_path(job_application_id: application.id)
    assert_selector ".input-group-text", exact_text: "$"
    { "EUR" => "€", "GBP" => "£", "JPY" => "¥", "CAD" => "$", "ZZZ" => "ZZZ", "EU" => "EU", "" => "—" }.each do |currency, symbol|
      fill_in "Currency", with: currency
      assert_selector ".input-group-text", exact_text: symbol
      assert_field "Agreed rate", with: "400.0"
    end
    page.refresh
    assert_selector ".input-group-text", exact_text: "$"
  ensure
    Warden.test_reset!
  end

  private

  def create_user(name)
    User.create!(first_name: name, last_name: "Currency", email: "currency-#{name}@example.com", password: "password123").tap do |user|
      user.profiles.create!(profile_type: "user", completed_at: Time.current)
      user.visits.create!
    end
  end
end
