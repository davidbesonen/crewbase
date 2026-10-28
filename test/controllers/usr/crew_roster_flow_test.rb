require "test_helper"

class Usr::CrewRosterFlowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    @owner = User.create!(first_name: "Roster", last_name: "Owner", email: "upload-owner@example.com", password: "password123")
    @owner.profiles.create!(profile_type: "user", completed_at: Time.current)
    @owner.visits.create!
    @company = Company.create!(name: "Import Crew Co", contact_email: @owner.email, industries: [ Industry.music_touring! ])
    @company.company_assignments.create!(user: @owner, role: "owner")
    sign_in @owner
  end

  test "upload opens an editable review and saves only selected valid people" do
    assert Rails.application.routes.url_helpers.respond_to?(:usr_company_crew_imports_path), "Crew spreadsheet imports need a review screen"
    file = Tempfile.new([ "review-crew", ".csv" ])
    file.write("First Name,Last Name,Email,Phone,Job Title,City,State,Years Worked With\nAlex,Audio,alex@example.com,,A1,Austin,TX,3\nSkip,Me,,,,,,\n")
    file.close
    assert_no_difference [ "CrewMember.count", "User.count" ] do
      post usr_company_crew_imports_path(@company), params: { spreadsheet: Rack::Test::UploadedFile.new(file.path, "text/csv") }
    end
    batch = @company.crew_imports.last
    assert_redirected_to usr_company_crew_import_path(@company, batch)
    follow_redirect!
    assert_select "h1", text: "Review Crew Import"
    assert_select "input[name='rows[0][city]'][value='Austin']"
    assert_select "[data-import-row]", count: 2
    assert_difference "CrewMember.count", 1 do
      patch usr_company_crew_import_path(@company, batch), params: { rows: {
        "0" => batch.rows.first.merge("include" => "1", "city" => "Nashville"),
        "1" => batch.rows.last.merge("include" => "0")
      } }
    end
    assert_redirected_to usr_company_crew_members_path(@company)
    assert_equal "Nashville", @company.crew_members.last.city
  ensure
    File.unlink(file.path) if file && File.exist?(file.path)
  end

  test "roster and import details are private to the company owner" do
    assert Rails.application.routes.url_helpers.respond_to?(:usr_company_crew_members_path), "Rosters need scoped owner access"
    member = @company.crew_members.create!(first_name: "Private", last_name: "Person", email: "private@example.com", notes: "Owner only")
    get usr_company_crew_members_path(@company)
    assert_response :success
    assert_select "a", text: "Upload Spreadsheet"
    sign_out @owner
    outsider = User.create!(first_name: "Other", last_name: "Owner", email: "outsider-roster@example.com", password: "password123")
    sign_in outsider
    get usr_company_crew_member_path(@company, member)
    assert_response :not_found
    sign_in outsider
    get usr_company_crew_members_path(@company)
    assert_response :not_found
  end

  test "invitation allows profile claim but never shows private company notes" do
    assert Rails.application.routes.url_helpers.respond_to?(:crew_claim_path), "Imported crew need a claim link"
    member = @company.crew_members.create!(first_name: "Invited", last_name: "Person", phone: "6155550199", notes: "Strictly company private")
    token = member.invitation_token!
    sign_out @owner
    get crew_claim_path(token)
    assert_response :success
    assert_select "input[value='Invited']"
    assert_not_includes response.body, "Strictly company private"
    worker = User.create!(first_name: "Invited", last_name: "Person", email: "phone-invite@example.com", password: "password123")
    sign_in worker
    post crew_claim_path(token)
    assert_redirected_to edit_usr_profile_path(worker.user_profile, source: "crew_roster")
    assert_equal worker.id, member.reload.profile.user_id
    get crew_claim_path(token)
    assert_response :not_found
  end

  test "roster search finds a contact by email or phone" do
    member = @company.crew_members.create!(first_name: "Morgan", last_name: "Stage", email: "morgan-stage@example.com", phone: "+1 (615) 555-0123")
    [ "morgan-stage@example.com", "555-0123", "6155550123" ].each do |query|
      get usr_company_crew_members_path(@company, q: query)
      assert_response :success
      assert_select "[data-crew-member='#{member.id}']"
    end
  end

  test "unavailable claim links explain recovery instead of showing a routing or record error" do
    sign_out @owner
    get crew_claim_path("expired-or-invalid")
    assert_response :not_found
    assert_select "h1", text: "This Invitation Is Unavailable"
    assert_select "a[href='#{new_user_session_path}']"
  end

  test "an invitation opened in the wrong account offers a safe account switch" do
    member = @company.crew_members.create!(first_name: "Crew", last_name: "Invitee", email: "invited-crew@example.com")
    token = member.invitation_token!
    get crew_claim_path(token)
    assert_select ".alert", text: /different account/
    assert_select "button", text: "Use A Different Account"
    assert_select "button", text: "Claim And Complete My Profile", count: 0
    post "/crew-invitations/#{token}/switch-account"
    assert_redirected_to new_user_session_path
    assert_nil member.reload.profile_id
    get crew_claim_path(token)
    assert_select "input[value='invited-crew@example.com']"
  end

  test "the advertised 500 person review can be submitted with every editable field" do
    rows = 500.times.map do |index|
      CrewMember::FIELDS.index_with { "" }.merge("first_name" => "Crew", "last_name" => "#{index}", "email" => "scale-#{index}@example.com", "include" => "1")
    end
    batch = @company.crew_imports.create!(uploaded_by: @owner, rows:)
    patch usr_company_crew_import_path(@company, batch), params: { rows_payload: rows.to_json }
    assert_redirected_to usr_company_crew_members_path(@company)
    assert_equal 500, @company.crew_members.count
  end

  test "malformed or oversized review shapes fail without adding crew" do
    batch = @company.crew_imports.create!(uploaded_by: @owner, rows: [ { "first_name" => "Original", "last_name" => "Person", "phone" => "6155550144" } ])
    [ "broken json", { "not" => "rows" }.to_json, [ "not a person" ].to_json, Array.new(501) { {} }.to_json ].each do |payload|
      assert_no_difference "CrewMember.count" do
        patch usr_company_crew_import_path(@company, batch), params: { rows_payload: payload }
      end
      assert_response :unprocessable_entity
      assert_select ".alert", text: /Nothing was added/
      assert_select "input[value='Original']"
    end
  end

  test "malformed ordinary form rows return a correctable review instead of a server error" do
    batch = @company.crew_imports.create!(uploaded_by: @owner, rows: [ { "first_name" => "Original", "last_name" => "Person", "phone" => "6155550144" } ])
    [ "not rows", [ "not a row" ], 42 ].each do |rows|
      assert_no_difference "CrewMember.count" do
        patch usr_company_crew_import_path(@company, batch), params: { rows: }
      end
      assert_response :unprocessable_entity
      assert_select ".alert", text: /Nothing was added/
    end
  end

  test "viewing a generated invitation never extends its original seven day deadline" do
    member = @company.crew_members.create!(first_name: "Expiry", last_name: "Crew", email: "expiry@example.com")
    member.invitation_token!
    refreshed_path = nil
    travel 6.days do
      get usr_company_crew_member_path(@company, member)
      assert_response :success
      refreshed_path = URI.parse(css_select("input#crew_claim_link").sole["value"]).path
    end
    travel 8.days do
      sign_out @owner
      get refreshed_path
      assert_response :not_found
    end
  end
end
