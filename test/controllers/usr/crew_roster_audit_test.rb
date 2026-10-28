require "test_helper"

class Usr::CrewRosterAuditTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    @owner = User.create!(first_name: "Audit", last_name: "Owner", email: "roster-audit@example.com", password: "password123")
    @owner.profiles.create!(profile_type: "user", completed_at: Time.current)
    @company = Company.create!(name: "Roster Audit Productions", contact_email: @owner.email, industries: [ Industry.music_touring! ])
    @company.company_assignments.create!(user: @owner, role: "owner")
    sign_in @owner
  end

  test "a real Excel workbook preserves contacts and experience without accounts profiles or emails" do
    assert_no_difference [ "CrewMember.count", "User.count", "Profile.count", "ActionMailer::Base.deliveries.count" ] do
      post usr_company_crew_imports_path(@company), params: { spreadsheet: workbook("valid") }
    end
    batch = @company.crew_imports.last
    assert_equal 5, batch.rows.size
    follow_redirect!
    assert_select "[data-import-row]", count: 5
    assert_select "script", text: /dummy-note/, count: 0
    assert_difference "CrewMember.count", 5 do
      assert_no_difference [ "User.count", "Profile.count", "ActionMailer::Base.deliveries.count" ] do
        patch usr_company_crew_import_path(@company, batch), params: { rows_payload: batch.rows.to_json }
      end
    end
    assert_redirected_to usr_company_crew_members_path(@company)
    assert_empty batch.reload.rows
    assert_equal 5, batch.imported_count
    assert @company.crew_members.all? { |member| member.profile_id.nil? && member.invitation_nonce.nil? }
    alex = @company.crew_members.find_by!(email: "alex.audio@example.com")
    assert_equal BigDecimal("3.5"), alex.years_with_company
    assert_equal "DiGiCo SD series\nDante", alex.equipment_text
    assert_equal "Live mixing\nSystem tuning", alex.skills_text
    assert_equal "16155550144", @company.crew_members.find_by!(email: "sam.backline@example.com").phone_key
    assert_equal "Montréal", @company.crew_members.find_by!(email: "renee.oconnor@example.com").city
    assert_no_difference "CrewMember.count" do
      patch usr_company_crew_import_path(@company, batch), params: { rows_payload: batch.rows.presence&.to_json || "[{}]" }
    end
    assert_redirected_to usr_company_crew_members_path(@company)
  end

  test "real Excel errors are reviewable and corrected selected rows import atomically" do
    post usr_company_crew_imports_path(@company), params: { spreadsheet: workbook("needs-review") }
    batch = @company.crew_imports.last
    follow_redirect!
    assert_select "[data-ready='false']", count: 7
    assert_select ".alert", text: /Duplicate contact/, minimum: 2
    assert_no_difference "CrewMember.count" do
      patch usr_company_crew_import_path(@company, batch), params: { rows_payload: batch.rows.to_json }
    end
    assert_response :unprocessable_entity
    assert_nil batch.reload.imported_at
    rows = batch.rows.map { |row| row.merge("include" => "0") }
    rows[0].merge!("include" => "1", "phone" => "6155550198", "city" => "Austin")
    assert_difference "CrewMember.count", 1 do
      patch usr_company_crew_import_path(@company, batch), params: { rows_payload: rows.to_json }
    end
    assert_redirected_to usr_company_crew_members_path(@company)
    assert_equal "Austin", @company.crew_members.sole.city
  end

  test "expired reviews and selecting no rows add nothing" do
    batch = @company.crew_imports.create!(uploaded_by: @owner, rows: [ attributes ])
    assert_no_difference "CrewMember.count" do
      patch usr_company_crew_import_path(@company, batch), params: { rows_payload: [ attributes.merge("include" => "0") ].to_json }
    end
    assert_response :unprocessable_entity
    travel 25.hours do
      assert_no_difference "CrewMember.count" do
        patch usr_company_crew_import_path(@company, batch), params: { rows_payload: [ attributes ].to_json }
      end
      assert_response :unprocessable_entity
      assert_select ".alert", text: /expired/
    end
  end

  test "invalid files and non-file inputs fail with a useful message" do
    [ nil, "not a file" ].each do |file|
      assert_no_difference [ "CrewImport.count", "CrewMember.count" ] do
        post usr_company_crew_imports_path(@company), params: { spreadsheet: file }
      end
      assert_response :unprocessable_entity
    end
  end

  test "links are invalid after replacement contact edits use removal or company suspension" do
    member = @company.crew_members.create!(attributes)
    old_token = member.invitation_token!
    replacement = member.invitation_token!
    sign_out @owner
    get crew_claim_path(old_token)
    assert_response :not_found
    get crew_claim_path(replacement)
    assert_response :success
    member.update!(email: "corrected@example.com")
    get crew_claim_path(replacement)
    assert_response :not_found
    token = member.invitation_token!
    @company.update!(restricted_at: Time.current)
    get crew_claim_path(token)
    assert_response :not_found
    @company.update!(restricted_at: nil)
    member.destroy!
    get crew_claim_path(token)
    assert_response :not_found
  end

  test "crew claim both companies invitations and each owner sees only their private roster record" do
    other_owner = User.create!(first_name: "Other", last_name: "Owner", email: "multi-roster-owner@example.com", password: "password123")
    other = Company.create!(name: "Second Roster Company", contact_email: other_owner.email, industries: @company.industries)
    other.company_assignments.create!(user: other_owner, role: "owner")
    worker = User.create!(first_name: "Shared", last_name: "Crew", email: "shared-crew@example.com", password: "password123")
    first = @company.crew_members.create!(first_name: "Shared", last_name: "Crew", email: worker.email, notes: "First company private note")
    second = other.crew_members.create!(first_name: "Shared", last_name: "Crew", email: worker.email, notes: "Second company private note")
    tokens = [ first.invitation_token!, second.invitation_token! ]
    sign_out @owner
    sign_in worker
    [ first, second ].zip(tokens).each do |member, token|
      get crew_claim_path(token)
      assert_response :success
      assert_not_includes response.body, "company private note"
      post crew_claim_path(token)
      assert_redirected_to edit_usr_profile_path(worker.reload.user_profile, source: "crew_roster")
      assert_equal worker.user_profile.id, member.reload.profile_id
    end
    assert_equal 1, worker.profiles.where(profile_type: "user").count
    assert_empty worker.company_assignments
    sign_in @owner
    get usr_company_crew_member_path(@company, first)
    assert_response :success
    assert_includes response.body, "First company private note"
    assert_not_includes response.body, "Second company private note"
    get usr_company_crew_member_path(other, second)
    assert_response :not_found
    sign_in @owner
    delete usr_company_crew_member_path(@company, first)
    assert_redirected_to usr_company_crew_members_path(@company)
    assert_equal worker.user_profile.id, second.reload.profile_id
    sign_in other_owner
    get usr_company_crew_member_path(other, second)
    assert_response :success
    assert_includes response.body, "Second company private note"
  end

  private

  def workbook(kind)
    Rack::Test::UploadedFile.new(Rails.root.join("test/data/crew-roster-#{kind}.xlsx"), "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
  end

  def attributes = { "first_name" => "Dummy", "last_name" => "Crew", "email" => "dummy.crew@example.com" }
end
