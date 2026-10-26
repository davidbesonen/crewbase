# Core duties come from the occupation; additional specialties and tools are explicit.
class OccupationExperienceCategories
  OCCUPATIONS = YAML.safe_load_file(Rails.root.join("config/occupation_experience.yml")).freeze

  def initialize(occupations)
    @occupations = occupations
  end

  def keys
    %w[Skill Equipment].to_h do |type|
      values = entries.flat_map { |entry| entry.fetch(type) }.uniq
      values -= core_keys if type == "Skill"
      values &= ExperienceCategories.selectable(type).map(&:key)
      [ type, ExperienceCategories.most_specific(type, values) ]
    end
  end

  def core_keys
    ExperienceCategories.implied_keys("Skill", entries.flat_map { |entry| entry.fetch("Core", []) })
  end

  # Used by directory search without loading each profile and its occupations.
  def self.names_covering(keys)
    OCCUPATIONS.filter_map do |name, entry|
      name.downcase if (ExperienceCategories.implied_keys("Skill", entry.fetch("Core", [])) & keys).any?
    end
  end

  private

  def entries
    @entries ||= @occupations.filter_map do |occupation|
      OCCUPATIONS.find { |name, _keys| name.casecmp?(occupation.name.to_s) }&.last
    end
  end
end
