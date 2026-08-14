require "test_helper"

class ViewBoundaryTest < ActiveSupport::TestCase
  VIEW_FILES = Dir[Rails.root.join("app/{views,components}/**/*.haml")].freeze
  QUERY_PATTERN = /\.(?:where|find|find_by|joins|includes|order|limit|pluck|exists\?|sum|average|maximum|minimum|all)\b/
  COMPONENT_RENDER_PATTERN = /\brender\s+[A-Z]\w*(?:::\w+)*Component\b/

  test "HAML templates do not build database queries" do
    violations = VIEW_FILES.filter_map do |path|
      matches = File.readlines(path).filter_map.with_index(1) do |line, number|
        "#{number}: #{line.strip}" if line.match?(QUERY_PATTERN)
      end
      "#{path.delete_prefix("#{Rails.root}/")}:\n  #{matches.join("\n  ")}" if matches.any?
    end

    assert_empty violations, "Move query construction out of HAML:\n#{violations.join("\n")}"
  end

  test "ViewComponents do not directly render other ViewComponents" do
    component_templates = VIEW_FILES.grep(%r{/app/components/})
    violations = component_templates.filter_map do |path|
      matches = File.readlines(path).filter_map.with_index(1) do |line, number|
        "#{number}: #{line.strip}" if line.match?(COMPONENT_RENDER_PATTERN)
      end
      "#{path.delete_prefix("#{Rails.root}/")}:\n  #{matches.join("\n  ")}" if matches.any?
    end

    assert_empty violations, "Compose nested ViewComponents through declared slots:\n#{violations.join("\n")}"
  end
end
