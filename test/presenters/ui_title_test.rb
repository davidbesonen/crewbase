require "test_helper"

class UiTitleTest < ActiveSupport::TestCase
  test "capitalizes heading words while preserving punctuation and contractions" do
    assert_equal "When, Where & Pay", UiTitle.format("When, where & pay")
    assert_equal "Invite To Apply", UiTitle.format("Invite to apply")
    assert_equal "What’s New?", UiTitle.format("What’s new?")
    assert_equal "Availability Without Back-And-Forth", UiTitle.format("Availability without back-and-forth")
  end

  test "preserves identities acronyms and product spelling" do
    assert_equal "KnowShow Credits & MA3 Experience", UiTitle.format("KnowShow Credits & MA3 experience")
    assert_equal "iCal, grandMA3 & David deHaven", UiTitle.format("iCal, grandMA3 & David deHaven")
    assert_equal "Équipe & Crew", UiTitle.format("équipe & crew")
  end
end
