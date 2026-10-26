require "test_helper"
require "haml"

class UiTitleConventionsTest < ActiveSupport::TestCase
  test "static UI headings use title case" do
    violations = Dir[Rails.root.join("app/{views,components}/**/*.haml")].flat_map do |path|
      tree = Haml::Parser.new({}).call(File.read(path))
      title_fragments(tree).filter_map do |line, text|
        next if text.blank? || text.include?('#{') || text == UiTitle.format(text)

        "#{path.delete_prefix("#{Rails.root}/")}:#{line}: #{text.inspect}"
      end
    end
    assert_empty violations, "Titleize UI headings; preserve authored names and body copy:\n#{violations.join("\n")}"
  end

  private

  def title_fragments(node, in_heading: false)
    if node.type == :tag
      in_heading ||= node.value[:name].match?(/\A(?:h[1-6]|summary|legend)\z/) ||
        node.value[:attributes].fetch("class", "").split.intersect?(%w[card-title card-section-title modal-title])
      own = in_heading && !node.value[:parse] ? [ [ node.line, node.value[:value] ] ] : []
    elsif node.type == :plain && in_heading
      own = [ [ node.line, node.value[:text] ] ]
    else
      own = []
    end
    own + node.children.flat_map { |child| title_fragments(child, in_heading:) }
  end
end
