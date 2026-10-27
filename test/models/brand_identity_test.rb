require "test_helper"

class BrandIdentityTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "Drive is the default including unrecognized or absent preview choices" do
    [ nil, "", "not-a-logo" ].each do |key|
      assert_equal "drive", BrandIdentity.concept(key).key
    end
  end

  test "explicit logo previews remain available" do
    assert_equal "signal", BrandIdentity.concept("signal").key
    assert_equal "momentum", BrandIdentity.concept("momentum").key
  end

  test "icon updates invalidate cached browser and home screen artwork" do
    assert_equal "/brand/knowshow-drive-icon.svg?v=2", BrandIdentity.icon_path
    assert_equal "/brand/knowshow-drive-icon.png?v=2", BrandIdentity.icon_path("png")
  end
end
