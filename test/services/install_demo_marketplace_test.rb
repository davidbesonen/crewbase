require "test_helper"

class InstallDemoMarketplaceTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "demo setup requires explicit opt in" do
    assert_raises(ArgumentError) do
      InstallDemoMarketplace.new(enabled: false, owner_password: "a-long-demo-password").call
    end
  end

  test "creates a usable fictional marketplace once without overwriting edits" do
    installer = InstallDemoMarketplace.new(enabled: true, owner_password: "a-long-demo-password")
    owner = installer.call
    assert owner.valid_password?("a-long-demo-password")
    assert owner.site_admin?
    assert_nil owner.provider
    assert owner.user_profile.completed_at.present?
    company = owner.owned_company_assignments.first.company
    assert company.jobs.accepting_applications.any?
    assert company.jobs.all? { |job| job.required_occupations.any? }
    assert User.where("email LIKE ?", "%@crewbase-demo.example").count >= 6
    owner.update!(first_name: "Edited")
    company.jobs.first.update!(title: "Friend's edited job")
    counts = [ User.count, Job.count, Company.count ]

    installer.call

    assert_equal counts, [ User.count, Job.count, Company.count ]
    assert_equal "Edited", owner.reload.first_name
    assert company.jobs.exists?(title: "Friend's edited job")
  end

  test "rejects a missing or weak owner password before creating data" do
    assert_no_difference "User.count" do
      assert_raises(ArgumentError) do
        InstallDemoMarketplace.new(enabled: true, owner_password: "").call
      end
    end
  end
end
