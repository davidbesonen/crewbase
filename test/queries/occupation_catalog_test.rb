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

  test "only touring roles are offered while saved out of scope roles stay removable" do
    touring = Occupation.create!(name: "Lighting Technician")
    actor = Occupation.create!(name: "Actor")
    instructor = Occupation.create!(name: "Instructor")
    assert_includes OccupationCatalog.new.records, touring
    assert_not_includes OccupationCatalog.new.records, actor
    assert_not_includes OccupationCatalog.new.records, instructor
    assert_includes OccupationCatalog.new(selected: [ actor ]).records, actor
    assert_not_includes OccupationCatalog.new.records(selected_ids: [ instructor.id ]), instructor
  end

  test "installation maintains only music touring occupations and industry" do
    previous_names = Industry.pluck(:name)
    InstallOccupationCatalog.new.call
    assert_equal [ "Live Music & Touring" ], Industry.pluck(:name) - previous_names
    assert_includes Occupation.pluck(:name), "Lighting Programmer"
    assert_includes Occupation.pluck(:name), "Musician"
    assert_not_includes Occupation.pluck(:name), "Actor"
    assert_not_includes Occupation.pluck(:name), "Mastering Engineer"
  end
end
