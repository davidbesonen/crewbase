# A bounded vocabulary of transferable work and tool families, never products.
class ExperienceCategories
  Category = Data.define(:key, :name, :description, :broader, :terms)
  GROUPS = { "Skill" => "skills", "Equipment" => "equipment" }.freeze
  PROFILE_FIELDS = { capability_keys: "Skill", equipment_family_keys: "Equipment" }.freeze
  JOB_FIELDS = {
    required_capability_keys: [ "Skill", "required" ],
    preferred_capability_keys: [ "Skill", "preferred" ],
    required_equipment_family_keys: [ "Equipment", "required" ],
    preferred_equipment_family_keys: [ "Equipment", "preferred" ]
  }.freeze

  CATALOG = YAML.safe_load_file(Rails.root.join("config/experience_categories.yml")).freeze

  def self.all(type)
    CATALOG.fetch(type).map do |key, entry|
      Category.new(key:, name: entry.fetch("name"), description: entry.fetch("description"),
        broader: entry["broader"], terms: entry.fetch("terms", []))
    end
  end

  # Retired umbrellas remain valid for saved profiles and job requirements.
  def self.selectable(type)
    all(type).reject { |category| CATALOG.fetch(type).fetch(category.key)["selectable"] == false }
  end

  # Directional: monitor mixing is audio experience; audio alone is not monitor mixing.
  def self.implied_keys(type, keys)
    known = CATALOG.fetch(type)
    Array(keys).flat_map do |key|
      family = []
      while key && known.key?(key) && !family.include?(key)
        family << key
        key = known.fetch(key)["broader"]
      end
      family
    end.uniq
  end

  def self.covers?(type, confirmed_keys, required_key)
    implied_keys(type, confirmed_keys).include?(required_key)
  end

  def self.most_specific(type, keys)
    keys.uniq.reject { |key| keys.any? { |other| key != other && covers?(type, [ other ], key) } }
  end

  def self.matching_names(type, keys)
    selected(type, implied_keys(type, keys)).map(&:name)
  end

  def self.search_keys(type, query)
    requested = all(type).select { |category| ExperienceTerms.key(category.name).include?(ExperienceTerms.key(query)) }.map(&:key)
    all(type).select { |category| (implied_keys(type, [ category.key ]) & requested).any? }.map(&:key)
  end

  def self.selected(type, keys)
    all(type).select { |entry| Array(keys).include?(entry.key) }
  end

  def self.profile_keys(profile, type)
    confirmed = profile.public_send(PROFILE_FIELDS.key(type))
    return confirmed if type != "Skill"

    (confirmed + OccupationExperienceCategories.new(profile.occupations).core_keys).uniq
  end
end
