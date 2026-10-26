require "test_helper"

class Usr::JobContractsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @owner = create_user("owner")
    @applicant = create_user("applicant")
    @outsider = create_user("outsider")
    industry = Industry.create!(name: "Contracts")
    @company = Company.create!(name: "Contract Company", contact_email: "contract-company@example.com", industries: [ industry ])
    @company.company_assignments.create!(user: @owner, role: "owner")
    @job = @company.jobs.create!(
      title: "Tour Contract Job",
      description: "Review the attached terms.",
      workplace_type: :on_site,
      employment_type: :contract,
      status: :published,
      is_active: true,
      published_at: Time.current
    )
    @applicant.user_profile.job_applications.create!(job: @job)
  end

  test "owner uploads a contract to the job and sees its tracking details" do
    sign_in @owner, scope: :user

    assert_difference("JobContract.count", 1) do
      post usr_job_contracts_path(@job), params: {
        job_contract: {
          title: "Crew services agreement",
          file: uploaded_contract
        }
      }
    end

    contract = JobContract.last
    assert_redirected_to usr_job_path(@job, anchor: "job-contracts")
    assert_equal @owner, contract.uploaded_by
    assert_equal "Crew services agreement", contract.title
    assert contract.file.attached?

    follow_redirect!
    assert_select "[data-job-contract='#{contract.id}']", text: /Crew services agreement/
    assert_select "[data-job-contract='#{contract.id}']", text: /Uploaded by #{@owner.full_name}/
  end

  test "non-owner cannot upload or delete a contract" do
    contract = create_contract
    sign_in @outsider, scope: :user

    assert_no_difference("JobContract.count") do
      post usr_job_contracts_path(@job), params: { job_contract: { file: uploaded_contract } }
    end
    assert_response :not_found

    sign_in @outsider, scope: :user
    assert_no_difference("JobContract.count") do
      delete usr_job_contract_path(@job, contract)
    end
    assert_response :not_found
  end

  test "hired applicant can see and download documents even after completion" do
    @job.job_applications.sole.update!(status: :accepted)
    @job.update!(status: :completed)
    contract = create_contract
    sign_in @applicant, scope: :user

    get usr_job_path(@job)
    assert_response :success
    assert_select "#job-contracts"
    assert_select "a[href='#{download_usr_job_contract_path(@job, contract)}']", text: /Download/

    get download_usr_job_contract_path(@job, contract)
    assert_response :success
    assert_equal "contract terms", response.body
    assert_includes response.headers["Content-Disposition"], "attachment"
  end

  test "contracts on unpublished jobs are hidden from non-owners" do
    contract = create_contract
    @job.update!(status: :draft, is_active: false)
    sign_in @applicant, scope: :user

    get download_usr_job_contract_path(@job, contract)

    assert_response :not_found
  end

  test "owner removes a contract from its job" do
    contract = create_contract
    sign_in @owner, scope: :user

    assert_difference("JobContract.count", -1) do
      delete usr_job_contract_path(@job, contract)
    end

    assert_redirected_to usr_job_path(@job, anchor: "job-contracts")
  end

  test "unhired applicants cannot see or download documents" do
    contract = create_contract
    sign_in @applicant, scope: :user
    get usr_job_path(@job)
    assert_response :success
    assert_select "#job-contracts", count: 0
    get download_usr_job_contract_path(@job, contract)
    assert_response :not_found
  end

  test "crew assignments grant document access and secondary owners retain management access" do
    @job.update!(posting_type: :multi_position)
    position = @job.crew_positions.create!(title: "Crew", headcount: 1)
    position.crew_assignments.create!(profile: @applicant.user_profile)
    contract = create_contract
    sign_in @applicant, scope: :user
    get download_usr_job_contract_path(@job, contract)
    assert_response :success
    @company.company_assignments.create!(user: @outsider, role: "owner")
    @job.update!(status: :draft)
    sign_in @outsider, scope: :user
    get usr_job_path(@job)
    assert_response :success
    assert_select "[data-contract-upload]"
  end

  private

  def create_user(label)
    user = User.create!(
      first_name: label.titleize,
      last_name: "Contracts",
      email: "#{label}-job-contracts@example.com",
      password: "password123"
    )
    user.profiles.create!(profile_type: "user", completed_at: Time.current)
    user.visits.create!
    user
  end

  def uploaded_contract
    Rack::Test::UploadedFile.new(
      StringIO.new("contract terms"),
      "application/pdf",
      false,
      original_filename: "crew-contract.pdf"
    )
  end

  def create_contract
    contract = @job.contracts.new(title: "Crew agreement", uploaded_by: @owner)
    contract.file.attach(
      io: StringIO.new("contract terms"),
      filename: "crew-agreement.pdf",
      content_type: "application/pdf"
    )
    contract.save!
    contract
  end
end
