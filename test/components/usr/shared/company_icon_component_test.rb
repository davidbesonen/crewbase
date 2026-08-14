# frozen_string_literal: true

require "test_helper"

class Usr::Shared::CompanyIconComponentTest < ViewComponent::TestCase
  self.fixture_table_names = []

  Company = Struct.new(:name, :image_url)

  test "keeps image and fallback icons square when rendered in a flex container" do
    [
      Company.new("Framehouse Studios", "https://example.com/logo.png"),
      Company.new("Framehouse Studios", nil)
    ].each do |company|
      result = render_inline(
        Usr::Shared::CompanyIconComponent.new(company: company, size: 72)
      )

      assert_includes result.children.first["style"], "flex: 0 0 72px"
    end
  end
end
