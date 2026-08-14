require "test_helper"

class UserFacingCopyTest < ActiveSupport::TestCase
  test "templates do not ship placeholder or coming-soon copy" do
    templates = Rails.root.glob("app/{components,views}/**/*.{haml,erb}")
    leftovers = templates.filter_map do |path|
      matches = path.readlines.filter_map.with_index(1) do |line, line_number|
        next unless line.match?(/placeholder for|component placeholder|uploads coming soon/i)

        "#{path.relative_path_from(Rails.root)}:#{line_number}: #{line.strip}"
      end
      matches if matches.any?
    end.flatten

    assert_empty leftovers, "Remove or replace user-facing placeholder copy:\n#{leftovers.join("\n")}"
  end
end
