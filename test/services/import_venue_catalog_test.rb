require "test_helper"

class ImportVenueCatalogTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "catalog refresh is idempotent and preserves company venue details" do
    assert Object.const_defined?(:ImportVenueCatalog), "The national venue catalog needs a repeatable import"
    rows = [ { "source_key" => "node/17", "name" => "Touring Hall", "city" => "Austin", "state" => "TX", "country" => "US" } ]
    assert_difference "VenueCatalogEntry.count", 1 do
      ImportVenueCatalog.new(rows:).call
      ImportVenueCatalog.new(rows:).call
    end
    owner = User.create!(first_name: "Venue", last_name: "Owner", email: "catalog-owner@example.com", password: "password123")
    company = Company.create!(name: "Private Venue Company", contact_email: owner.email, industries: [ Industry.music_touring! ])
    venue = company.venues.create!(name: "Company Hall", venue_catalog_entry: VenueCatalogEntry.find_by!(source_key: "node/17"), contact_email: "private@example.com", load_in_notes: "Private dock instructions")
    rows.first["name"] = "Updated Hall"
    assert_no_difference "VenueCatalogEntry.count" do
      ImportVenueCatalog.new(rows:).call
    end
    assert_equal "Updated Hall", VenueCatalogEntry.find_by!(source_key: "node/17").name
    assert_equal "Company Hall", venue.reload.name
    assert_equal "private@example.com", venue.contact_email
    assert_equal "Private dock instructions", venue.load_in_notes
  end
  test "bundled catalog covers every state and includes major touring venues" do
    rows = JSON.parse(Rails.root.join("public/data/us-venues.json").read)
    assert_operator rows.size, :>, 10000
    assert_equal rows.size, rows.map { |row| row.fetch("source_key") }.uniq.size
    states = rows.map { |row| row.fetch("state") }.uniq
    expected = %w[AL AK AZ AR CA CO CT DE FL GA HI ID IL IN IA KS KY LA ME MD MA MI MN MS MO MT NE NV NH NJ NM NY NC ND OH OK OR PA RI SC SD TN TX UT VT VA WA WV WI WY]
    assert_empty expected - states
    assert rows.all? { |row| row["country"] == "US" && row["licenses"].present? }
    assert rows.any? { |row| row["name"] == "Red Rocks Park And Amphitheatre" && row["city"] == "Morrison" }
    assert rows.any? { |row| row["name"] == "Madison Square Garden" && row["city"] == "New York" }
  end
end
