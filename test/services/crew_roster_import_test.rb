require "test_helper"

class CrewRosterImportTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    @owner = User.create!(first_name: "Tour", last_name: "Owner", email: "roster-owner@example.com", password: "password123")
    @company = Company.create!(name: "Roster Productions", contact_email: @owner.email, industries: [ Industry.music_touring! ])
    @company.company_assignments.create!(user: @owner, role: "owner")
  end

  test "spreadsheet preview creates no crew or user accounts" do
    assert defined?(CrewRosterSpreadsheet), "A spreadsheet upload must have a review step"
    file = upload("First Name,Last Name,Email,Phone,City,State,Years Worked With,Job Title,Equipment\nDayne,Lighting,dayne@example.com,,Nashville,TN,4,Lighting Director,grandMA3\n")
    assert_no_difference [ "User.count", "Profile.count", "CrewMember.count" ] do
      rows = CrewRosterSpreadsheet.new(file:).rows
      assert_equal "Nashville", rows.first.fetch("city")
      assert_equal "4", rows.first.fetch("years_with_company")
      assert_equal "Lighting Director", rows.first.fetch("role")
      assert_equal "grandMA3", rows.first.fetch("equipment_text")
    end
  end

  test "xlsx template can be uploaded and includes helpful roster columns" do
    assert defined?(CrewRosterTemplate), "Provide an Excel template for roster uploads"
    file = Tempfile.new([ "crew-template", ".xlsx" ])
    file.binmode
    file.write(CrewRosterTemplate.new.to_xlsx)
    file.rewind
    workbook = Roo::Excelx.new(file.path)
    assert_includes workbook.row(1), "Years Worked With"
    assert_includes workbook.row(1), "Phone"
    assert_includes workbook.row(1), "Equipment"
    assert_empty CrewRosterSpreadsheet.new(file: Rack::Test::UploadedFile.new(file.path, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")).rows
  ensure
    file&.close!
  end

  test "every selected row needs email or phone and errors prevent partial imports" do
    assert defined?(CrewRosterImport), "Only reviewed, valid crew should be imported"
    batch = @company.crew_imports.create!(uploaded_by: @owner, rows: [])
    rows = [ attributes.merge("email" => "alex@example.com"), attributes.merge("first_name" => "No", "last_name" => "Contact") ]
    assert_no_difference "CrewMember.count" do
      result = CrewRosterImport.new(import: batch, rows:).call
      assert_not result.success?
      assert_match /email or phone/i, result.error
    end
  end

  test "reviewed rows import once, preserve company history and normalize contacts" do
    assert defined?(CrewRosterImport), "Reviewed crew must be saved atomically"
    batch = @company.crew_imports.create!(uploaded_by: @owner, rows: [])
    rows = [ attributes.merge("email" => " ALEX@EXAMPLE.COM ", "years_with_company" => "3.5", "notes" => "Company-only note") ]
    assert_difference "CrewMember.count", 1 do
      assert_no_difference [ "User.count", "Profile.count" ] do
        result = CrewRosterImport.new(import: batch, rows:).call
        assert result.success?, result.error
      end
    end
    member = @company.crew_members.last
    assert_equal "alex@example.com", member.email
    assert_equal BigDecimal("3.5"), member.years_with_company
    assert_equal "Company-only note", member.notes
    assert_nil member.profile_id
    assert_no_difference "CrewMember.count" do
      assert CrewRosterImport.new(import: batch.reload, rows:).call.success?
    end
  end

  test "duplicate contacts in the spreadsheet or company require review" do
    assert defined?(CrewRosterImport), "Duplicates must be identified before adding crew"
    @company.crew_members.create!(attributes.merge("phone" => "+1 (615) 555-0123"))
    batch = @company.crew_imports.create!(uploaded_by: @owner, rows: [])
    assert_no_difference "CrewMember.count" do
      result = CrewRosterImport.new(import: batch, rows: [ attributes.merge("phone" => "+1 615-555-0123") ]).call
      assert_not result.success?
      assert_match /already|duplicate/i, result.error
    end
  end

  test "a zip file renamed as Excel is rejected as an unreadable spreadsheet" do
    file = Tempfile.new([ "not-a-workbook", ".xlsx" ])
    Zip::OutputStream.open(file.path) { |zip| zip.put_next_entry("notes.txt"); zip.write("Not a spreadsheet") }
    assert_raises CrewRosterSpreadsheet::InvalidFile do
      CrewRosterSpreadsheet.new(file: Rack::Test::UploadedFile.new(file.path, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")).rows
    end
  ensure
    file&.close!
  end

  test "duplicates inside one upload roll back earlier rows" do
    batch = @company.crew_imports.create!(uploaded_by: @owner, rows: [])
    rows = [ attributes.merge("email" => "same@example.com"), attributes.merge("first_name" => "Another", "email" => "SAME@example.com") ]
    assert_no_difference "CrewMember.count" do
      assert_not CrewRosterImport.new(import: batch, rows:).call.success?
    end
    assert_nil batch.reload.imported_at
  end

  test "invalid years must be corrected rather than silently imported" do
    batch = @company.crew_imports.create!(uploaded_by: @owner, rows: [])
    assert_no_difference "CrewMember.count" do
      result = CrewRosterImport.new(import: batch, rows: [ attributes.merge("phone" => "6155550180", "years_with_company" => "many") ]).call
      assert_not result.success?
      assert_match /number/i, result.error
    end
  end

  test "import flags experience entries that would prevent the person claiming their profile" do
    batch = @company.crew_imports.create!(uploaded_by: @owner, rows: [])
    result = CrewRosterImport.new(import: batch, rows: [ attributes.merge("email" => "long-experience@example.com", "equipment_text" => "x" * 81) ]).call
    assert_not result.success?
    assert_match /80 characters/i, result.error
  end

  test "validation identifies people instead of misleading row numbers and bounds the summary" do
    batch = @company.crew_imports.create!(uploaded_by: @owner, rows: [])
    rows = 5.times.map { |i| attributes.merge("first_name" => "Missing#{i}") }
    result = CrewRosterImport.new(import: batch, rows:).call
    assert_not result.success?
    assert_match /Missing0 Audio/, result.error
    assert_match /2 more crew/, result.error
    refute_match /Row 1:/, result.error
    assert_nil batch.reload.imported_at
  end

  private

  def attributes
    { "first_name" => "Alex", "last_name" => "Audio", "role" => "FOH Engineer" }
  end

  def upload(contents)
    file = Tempfile.new([ "roster", ".csv" ])
    file.write(contents)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, "text/csv")
  end
end
