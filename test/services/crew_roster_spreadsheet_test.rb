require "test_helper"
require "caxlsx"

class CrewRosterSpreadsheetTest < ActiveSupport::TestCase
  self.fixture_table_names = []
  HEADERS = [ "First Name", "Last Name", "Email" ].freeze

  setup { @files = [] }
  teardown { @files.each(&:close!) }

  test "real Excel limit accepts 500 people and rejects 501" do
    [ 500, 501 ].each do |count|
      file = excel(Array.new(count) { |i| [ "Crew", i.to_s, "crew-#{i}@example.com" ] })
      if count == 500
        assert_equal count, CrewRosterSpreadsheet.new(file:).rows.size
      else
        assert_invalid(file, /500/)
      end
    end
  end

  test "empty and oversized files unsupported extensions and corrupt Excel produce helpful errors" do
    assert_invalid(upload(".csv", ""), /5 MB/)
    assert_invalid(upload(".csv", "x" * (CrewRosterSpreadsheet::MAX_BYTES + 1)), /5 MB/)
    assert_invalid(upload(".xls", "old workbook"), /xlsx/)
    assert_invalid(upload(".xlsx", "not a zip file"), /could not be read/i)
    assert_invalid(upload(".csv", "\"unterminated\n"), /could not be read/i)
    assert_invalid(upload(".csv", "First Name,Last Name,Email\nBad,Encoding,\xff\n".b), /could not be read/i)
  end

  test "missing and duplicate mapped headers are rejected" do
    assert_invalid(excel([ [ "Alex", "a@example.com" ] ], headers: [ "First Name", "Email" ]), /First Name and Last Name/)
    assert_invalid(excel([ [ "Alex", "Crew" ] ], headers: [ "First Name", "Last Name" ]), /Email and\/or Phone/)
    assert_invalid(excel([], headers: [ *HEADERS, "Email Address" ]), /same field/)
    assert_invalid(excel([], headers: [ *HEADERS, *Array.new(28, "Unused") ]), /30 columns/)
  end

  test "BOM Unicode blank rows header aliases and unknown columns retain useful data" do
    file = upload(".csv", "\uFEFFFirst Name,Last Name,Email Address,Mobile Phone,Unknown\nRenée,O’Connor,renee@example.com,+44 7700 900123,ignored\n,,,,\n")
    rows = CrewRosterSpreadsheet.new(file:).rows
    assert_equal 1, rows.size
    assert_equal "Renée", rows.sole["first_name"]
    assert_equal "+44 7700 900123", rows.sole["phone"]
    assert_equal %w[first_name last_name email phone], rows.sole.keys
  end

  test "large zip expansion and too many archive entries are rejected before workbook parsing" do
    file = temporary(".xlsx")
    Zip::OutputStream.open(file.path) do |zip|
      zip.put_next_entry("padding.xml")
      zip.write("x" * 26.megabytes)
    end
    assert_invalid(as_upload(file), /too large/)
    Zip::OutputStream.open(file.path) do |zip|
      1001.times { |i| zip.put_next_entry("entry-#{i}.xml"); zip.write("x") }
    end
    assert_invalid(as_upload(file), /too large/)
  end

  test "damaged workbook metadata is rejected without exposing a parser exception" do
    [ "xl/workbook.xml", "xl/_rels/workbook.xml.rels", "xl/worksheets/sheet1.xml", "xl/sharedStrings.xml" ].each do |entry|
      file = temporary(".xlsx")
      FileUtils.cp(Rails.root.join("test/data/crew-roster-valid.xlsx"), file.path)
      Zip::File.open(file.path) { |archive| archive.get_output_stream(entry) { |stream| stream.write("<broken") } }
      assert_invalid(as_upload(file), /could not be read/i)
    end
  end

  test "actual expanded bytes are bounded even when ZIP metadata understates the size" do
    file = temporary(".xlsx")
    Zip::OutputStream.open(file.path) do |zip|
      zip.put_next_entry("xl/workbook.xml")
      zip.write("x" * 26.megabytes)
    end
    contents = File.binread(file.path)
    central = contents.index("PK\x01\x02".b)
    contents[central + 24, 4] = [ 0 ].pack("V")
    contents[22, 4] = [ 0 ].pack("V")
    File.binwrite(file.path, contents)
    assert_invalid(as_upload(file), /too large/)
  end

  test "empty unrelated ZIP entries do not invalidate a usable workbook" do
    file = temporary(".xlsx")
    FileUtils.cp(Rails.root.join("test/data/crew-roster-valid.xlsx"), file.path)
    Zip::File.open(file.path) { |archive| archive.get_output_stream("empty.bin") { |_stream| } }
    assert_equal 5, CrewRosterSpreadsheet.new(file: as_upload(file)).rows.size
  end

  private

  def temporary(extension)
    Tempfile.new([ "crew-parser-audit", extension ]).tap { |file| @files << file }
  end

  def as_upload(file) = Rack::Test::UploadedFile.new(file.path, "application/octet-stream")

  def upload(extension, contents)
    file = temporary(extension)
    file.binmode
    file.write(contents)
    file.flush
    as_upload(file)
  end

  def excel(rows, headers: HEADERS)
    file = temporary(".xlsx")
    package = Axlsx::Package.new
    package.workbook.add_worksheet(name: "Crew") do |sheet|
      sheet.add_row headers
      rows.each { |row| sheet.add_row row }
    end
    package.serialize(file.path)
    as_upload(file)
  end

  def assert_invalid(file, message)
    error = assert_raises(CrewRosterSpreadsheet::InvalidFile) { CrewRosterSpreadsheet.new(file:).rows }
    assert_match message, error.message
  end
end
