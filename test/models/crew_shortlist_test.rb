require "test_helper"

class CrewShortlistTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "requires a name" do
    shortlist = CrewShortlist.new(name: "")

    shortlist.validate

    assert_includes shortlist.errors[:name], "can't be blank"
  end
end
