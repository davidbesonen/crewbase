require "test_helper"

class ExperienceTermsTest < ActiveSupport::TestCase
  test "normalizes whitespace and duplicate entries without damaging technical names" do
    terms = ExperienceTerms.new("  Pro Tools  \r\npro tools\n C++ \nRF   coordination\nSound, lighting & video\n")
    assert_equal [ "Pro Tools", "C++", "RF coordination", "Sound, lighting & video" ], terms.values
    assert terms.include?("  PRO   TOOLS ")
    assert_not terms.include?("Tools")
    assert_not ExperienceTerms.new("C++").include?("C")
  end
end
