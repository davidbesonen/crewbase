require "test_helper"

class Usr::JobContractsComponentTest < ViewComponent::TestCase
  include Rails.application.routes.url_helpers

  self.fixture_table_names = []

  setup do
    @owner = User.create!(
      first_name: "Contract",
      last_name: "Owner",
      email: "contract-component-owner@example.com",
      password: "password123"
    )
    industry = Industry.create!(name: "Contract Component")
    company = Company.create!(name: "Component Company", contact_email: "component-contracts@example.com", industries: [ industry ])
    @job = company.jobs.create!(
      title: "Component Job",
      description: "Contract component test.",
      workplace_type: :remote,
      employment_type: :contract,
      status: :published,
      is_active: true
    )
    @contract = @job.contracts.new(title: "Production agreement", uploaded_by: @owner)
    @contract.file.attach(io: StringIO.new("terms"), filename: "agreement.pdf", content_type: "application/pdf")
    @contract.save!
  end

  test "owner sees document tracking, download, upload, and removal controls" do
    render_inline Usr::JobContractsComponent.new(job: @job, contracts: [ @contract ], owner: true)

    assert_selector "#job-contracts"
    assert_text "Production agreement"
    assert_text "Uploaded by Contract Owner"
    assert_selector "form[action='#{usr_job_contracts_path(@job)}']"
    assert_selector "a[href='#{download_usr_job_contract_path(@job, @contract)}'][data-turbo='false']", text: /Download/
    assert_selector "form[action='#{usr_job_contract_path(@job, @contract)}']", text: /Remove/
  end

  test "viewer gets download access without management controls" do
    render_inline Usr::JobContractsComponent.new(job: @job, contracts: [ @contract ], owner: false)

    assert_selector "a[href='#{download_usr_job_contract_path(@job, @contract)}']", text: /Download/
    assert_no_selector "[data-contract-upload]"
    assert_no_selector "form[action='#{usr_job_contract_path(@job, @contract)}']"
  end
end
