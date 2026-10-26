require "test_helper"

class OccupationCatalogTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "installs specific occupations idempotently without adding skills or equipment" do
    counts = [ Skill.count, Equipment.count ]
    InstallOccupationCatalog.new.call
    ids = Occupation.where(category_key: nil).ids
    InstallOccupationCatalog.new.call
    assert_equal ids.sort, Occupation.where(category_key: nil).ids.sort
    assert_equal counts, [ Skill.count, Equipment.count ]
    assert Occupation.exists?(name: "Audio Engineer", category_key: nil)
  end

  test "occupation catalog retains selected broad roles but offers specific occupations" do
    specific = Occupation.create!(name: "Camera Operator")
    previous = Occupation.create!(name: "Camera & photography", category_key: "camera")
    hidden = Occupation.create!(name: "Audio & sound", category_key: "audio")
    options = OccupationCatalog.new(selected: [ previous ]).records
    assert_includes options, specific
    assert_includes options, previous
    assert_not_includes options, hidden
  end
end
