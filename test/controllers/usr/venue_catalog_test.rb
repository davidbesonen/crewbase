require "test_helper"

class Usr::VenueCatalogTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    @user = User.create!(first_name: "Venue", last_name: "Search", email: "venue-search@example.com", password: "password123")
    sign_in @user
  end

  test "venue search matches venue and city without exposing company contacts" do
    assert Object.const_defined?(:VenueCatalogEntry), "A shared searchable venue catalog is required"
    VenueCatalogEntry.create!(source_key: "way/1", name: "Red Rocks Amphitheatre", city: "Morrison", state: "CO", country: "US", address: "18300 West Alameda Parkway")
    VenueCatalogEntry.create!(source_key: "way/2", name: "Red Hat Amphitheater", city: "Raleigh", state: "NC", country: "US")
    get usr_venue_catalog_index_path, params: { q: "red morrison" }, as: :json
    assert_response :success
    entries = response.parsed_body.fetch("venues")
    assert_equal [ "Red Rocks Amphitheatre" ], entries.map { |entry| entry.fetch("name") }
    assert_equal "Morrison", entries.sole.fetch("city")
    assert_not entries.sole.key?("contact_email")
    get usr_venue_catalog_index_path, params: { q: "%" }, as: :json
    assert_empty response.parsed_body.fetch("venues")
    sign_out @user
    get usr_venue_catalog_index_path, params: { q: "red" }, as: :json
    assert_response :unauthorized
  end
end
