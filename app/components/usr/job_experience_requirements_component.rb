class Usr::JobExperienceRequirementsComponent < ApplicationComponent
  LABELS = { "Occupation" => "occupations", "Skill" => "skills", "Equipment" => "equipment" }.freeze
  CATEGORY_LABELS = { "Skill" => "capabilities", "Equipment" => "equipment families" }.freeze

  def initialize(entries:)
    @entries = entries
  end

  def render?
    @entries.any?
  end

  def groups
    %w[required preferred].flat_map do |importance|
      [ [ CATEGORY_LABELS, true ], [ LABELS, false ] ].flat_map do |labels, categories|
        labels.filter_map do |type, label|
          names = @entries.select { |entry| entry.type == type && entry.importance == importance && entry.category_key.present? == categories }.map(&:name).uniq
          { label: "#{importance.capitalize} #{label}", names: names } if names.any?
        end
      end
    end
  end
end
