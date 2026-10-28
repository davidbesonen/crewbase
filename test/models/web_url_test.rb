require "test_helper"

class WebUrlTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "normalizes bare domains and preserves web links" do
    assert_equal "https://example.com/crew", WebUrl.normalize(" example.com/crew ")
    assert_equal "http://example.com", WebUrl.normalize("http://example.com")
    assert_equal "https://example.com", WebUrl.normalize("//example.com")
  end

  test "rejects executable schemes credentials malformed URLs and relative paths" do
    [ "javascript:alert(1)", "data:text/html,test", "https://user:password@example.com", "/crew", "https://", "bad url", "java\nscript:alert(1)", "" ].each do |value|
      assert_nil WebUrl.normalize(value), value.inspect
    end
  end
end
