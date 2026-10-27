require "test_helper"

class Usr::CrewRosterUploadAccessTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    @owner = make_user("owner")
    @employee = make_user("employee")
    @outsider = make_user("outsider")
    @company = Company.create!(name: "Roster Access Co", contact_email: @owner.email, is_public: true, industries: [ Industry.music_touring! ])
    @company.company_assignments.create!(user: @owner, role: "owner")
    @company.company_assignments.create!(user: @employee, role: "employee")
    @company.company_plans.create!(plan: Plan.create!(PricingCatalog.definitions.last))
  end

  test "company page and owner dashboard prominently link directly to uploading" do
    [ @owner, @employee ].each do |user|
      sign_in user
      get usr_company_path(@company)
      assert_select "[data-crew-roster-upload] a[href='#{new_usr_company_crew_import_path(@company)}']", text: "Upload Crew Roster"
    end
    sign_in @owner
    get usr_company_manager_path(@company)
    assert_response :success
    assert_select "[data-crew-roster-upload] a[href='#{new_usr_company_crew_import_path(@company)}']", text: "Upload Crew Roster"
  end

  test "an employee can upload review and confirm a spreadsheet without owner controls" do
    sign_in @employee
    get new_usr_company_crew_import_path(@company)
    assert_response :success
    assert_select "[data-company-owner-nav]", count: 0
    get template_usr_company_crew_imports_path(@company)
    assert_response :success
    file = Tempfile.new([ "employee-roster", ".csv" ])
    file.write("First Name,Last Name,Email\nAlex,Audio,employee-import@example.com\n")
    file.close
    assert_difference "CrewImport.count", 1 do
      post usr_company_crew_imports_path(@company), params: { spreadsheet: Rack::Test::UploadedFile.new(file.path, "text/csv") }
    end
    batch = @company.crew_imports.last
    follow_redirect!
    assert_response :success
    assert_select "a[href='#{usr_company_path(@company)}']", text: "Back To Company"
    assert_difference "CrewMember.count", 1 do
      patch usr_company_crew_import_path(@company, batch), params: { rows: { "0" => batch.rows.first } }
    end
    assert_redirected_to usr_company_path(@company)
  ensure
    file&.unlink
  end

  test "outsiders and roster contacts cannot discover upload controls or use import endpoints" do
    @company.crew_members.create!(first_name: "Outside", last_name: "Contact", email: @outsider.email, profile: @outsider.user_profile)
    sign_in @outsider
    get usr_company_path(@company)
    assert_select "[data-crew-roster-upload]", count: 0
    batch = @company.crew_imports.create!(uploaded_by: @owner, rows: [])
    [ new_usr_company_crew_import_path(@company), template_usr_company_crew_imports_path(@company), usr_company_crew_import_path(@company, batch) ].each do |path|
      sign_in @outsider
      get path
      assert_response :not_found
    end
    sign_in @outsider
    assert_no_difference "CrewImport.count" do
      post usr_company_crew_imports_path(@company), params: {}
    end
    assert_response :not_found
    sign_in @outsider
    assert_no_difference "CrewMember.count" do
      patch usr_company_crew_import_path(@company, batch), params: { rows: {} }
    end
    assert_response :not_found
  end

  test "employee upload access is limited to their company and revoked immediately" do
    sign_in @employee
    other = Company.create!(name: "Other Roster Co", contact_email: @owner.email, industries: @company.industries)
    get new_usr_company_crew_import_path(other)
    assert_response :not_found
    @employee.company_assignments.destroy_all
    sign_in @employee
    get new_usr_company_crew_import_path(@company)
    assert_response :not_found
  end

  test "legacy employee memberships can upload but other assignment roles cannot" do
    assignment = @employee.company_assignments.find_by!(company: @company)
    assignment.update!(role: "member")
    sign_in @employee
    get new_usr_company_crew_import_path(@company)
    assert_response :success
    assignment.update!(role: "viewer")
    get new_usr_company_crew_import_path(@company)
    assert_response :not_found
  end

  private

  def make_user(name)
    user = User.create!(first_name: name, last_name: "Upload", email: "roster-access-#{name}@example.com", password: "password123")
    user.profiles.create!(profile_type: "user", completed_at: Time.current)
    user.visits.create!
    user
  end
end
