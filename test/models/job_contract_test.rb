require "test_helper"

class JobContractTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    owner = User.create!(
      first_name: "Contract",
      last_name: "Owner",
      email: "contract-model-owner@example.com",
      password: "password123"
    )
    industry = Industry.create!(name: "Contract Model")
    company = Company.create!(
      name: "Contract Model Company",
      contact_email: "contracts@example.com",
      industries: [ industry ]
    )
    company.company_assignments.create!(user: owner, role: "owner")
    @job = company.jobs.create!(
      title: "Contract Job",
      description: "A job with documents.",
      workplace_type: :remote,
      employment_type: :contract,
      status: :published,
      is_active: true
    )
    @owner = owner
  end

  test "uses the uploaded filename as the title when no title is supplied" do
    contract = @job.contracts.new(uploaded_by: @owner)
    contract.file.attach(
      io: StringIO.new("contract terms"),
      filename: "tour-services-agreement.pdf",
      content_type: "application/pdf"
    )

    assert contract.save
    assert_equal "tour-services-agreement.pdf", contract.title
  end

  test "requires a supported contract document" do
    contract = @job.contracts.new(title: "Unsafe file", uploaded_by: @owner)
    contract.file.attach(
      io: StringIO.new("#!/bin/sh"),
      filename: "contract.sh",
      content_type: "application/x-sh"
    )

    assert_not contract.valid?
    assert_includes contract.errors[:file], "must be a supported document or image"
  end
end
