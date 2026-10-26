require "test_helper"

class EquipmentTermsTest < ActiveSupport::TestCase
  test "common console spellings do not create duplicate named requirements" do
    assert_equal [ "MA3", "MA2" ], EquipmentTerms.new("MA3\ngrandMA3\nMA 3\nMA2").values
    job = Job.new(required_equipment_text: "MA3\ngrandMA3")
    assert_equal [ "MA3" ], JobExperienceRequirements.new(job).names_for(:required_equipment_text)
  end

  test "MA3 aliases find reported console experience without confusing generations" do
    terms = EquipmentTerms.new("grandMA3 full-size\nDiGiCo SD12")
    %w[MA3 grandMA3].each { |query| assert terms.include?(query), query }
    assert terms.include?("MA 3")
    assert_not terms.include?("MA2")
    assert_not EquipmentTerms.new("grandMA2\nLighting consoles & control software").include?("MA3")
    assert_not EquipmentTerms.new("MA30").include?("MA3")
    assert_not terms.include?("DiGiCo SD7")
  end
end
