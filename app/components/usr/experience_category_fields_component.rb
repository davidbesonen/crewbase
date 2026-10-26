class Usr::ExperienceCategoryFieldsComponent < ApplicationComponent
  renders_one :suggestions

  LABELS = {
    capability_keys: "Additional capabilities & services", equipment_family_keys: "Equipment & software families",
    required_capability_keys: "Required capabilities", preferred_capability_keys: "Preferred capabilities",
    required_equipment_family_keys: "Required equipment families", preferred_equipment_family_keys: "Preferred equipment families"
  }.freeze

  def initialize(record:, scope:, occupations: [], selected_occupation_ids: [])
    @record = record
    @scope = scope.to_s
    @occupations = occupations
    @selected_occupation_ids = selected_occupation_ids.map(&:to_i)
  end

  attr_reader :scope

  def occupation_categories
    @occupations.to_h do |occupation|
      guidance = OccupationExperienceCategories.new([ occupation ])
      [ occupation.id, guidance.keys.merge("Core" => guidance.core_keys) ]
    end
  end

  def guidance
    @guidance ||= OccupationExperienceCategories.new(@occupations.select { |occupation| @selected_occupation_ids.include?(occupation.id) })
  end

  def coverage
    %w[Skill Equipment].to_h do |type|
      [ type, ExperienceCategories.all(type).to_h { |category| [ category.key, ExperienceCategories.implied_keys(type, [ category.key ]) ] } ]
    end
  end

  def groups
    fields = scope == "profile" ? ExperienceCategories::PROFILE_FIELDS : ExperienceCategories::JOB_FIELDS
    fields.map do |field, value|
      type = Array(value).first
      selected = @record.public_send(field)
      relevant = guidance.keys.fetch(type)
      core = type == "Skill" ? guidance.core_keys : []
      redundant = (core + ExperienceCategories.implied_keys(type, selected)) - selected
      available = (ExperienceCategories.selectable(type) + ExperienceCategories.selected(type, selected)).uniq
      primary, other = available.partition { |category| relevant.empty? || relevant.include?(category.key) || selected.include?(category.key) }
      primary.sort_by! { |category| relevant.index(category.key) || relevant.length }
      other.sort_by!(&:name)
      { field:, type:, label: LABELS.fetch(field), selected:, redundant:,
        core_names: ExperienceCategories.selected(type, ExperienceCategories.most_specific(type, core)).map(&:name),
        sections: { primary: primary, other: other }, tailored: relevant.any?,
        names: ExperienceCategories.selected(type, selected).map(&:name), errors: @record.errors.full_messages_for(field) }
    end
  end
end
