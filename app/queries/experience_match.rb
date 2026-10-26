require Rails.root.join("db/catalogs/experience_v1")

# Compare reported experience without maintaining a shared skill/product catalog.
# Notes and broader categories never substitute for an explicitly named entry.
class ExperienceMatch
  TYPES = %w[Occupation Skill Equipment].freeze

  def initialize(profile:, job:)
    @profile = profile
    @job = job
  end

  def names
    @names ||= TYPES.to_h do |type|
      matches = if requirements.empty?
        type == "Occupation" ? reported_names(type) : reported_names(type).select { |name| mentioned?(name) }
      else
        distinct_categories(requirements.select { |entry| entry.type == type && matches?(entry) }).map(&:name)
      end
      [ type, ExperienceTerms.new(without_broader_names(type, matches)).values ]
    end
  end

  def missing_requirements
    distinct_categories(requirements.select { |entry| entry.required? && !matches?(entry) })
      .uniq { |entry| [ entry.type, ExperienceTerms.key(entry.name) ] }
  end

  private

  def without_broader_names(type, names)
    return names if type == "Occupation"

    normalized = names.map { |name| ExperienceTerms.key(name) }
    categories = ExperienceCategories.all(type).select { |category| normalized.include?(ExperienceTerms.key(category.name)) }
    specific = ExperienceCategories.most_specific(type, categories.map(&:key))
    redundant = categories.reject { |category| specific.include?(category.key) }.map { |category| ExperienceTerms.key(category.name) }
    names.reject { |name| redundant.include?(ExperienceTerms.key(name)) }
  end

  # A broad family and its specialty describe the same evidence, not two matches.
  def distinct_categories(entries)
    entries.reject do |entry|
      entry.category_key && entries.any? do |other|
        other.type == entry.type && other.category_key && other.category_key != entry.category_key &&
          ExperienceCategories.covers?(entry.type, [ other.category_key ], entry.category_key)
      end
    end
  end

  def requirements
    @requirements ||= JobExperienceRequirements.new(@job).entries
  end

  def matches?(entry)
    return @profile.occupations.include?(entry.record) if entry.type == "Occupation"
    return ExperienceCategories.covers?(entry.type, ExperienceCategories.profile_keys(@profile, entry.type), entry.category_key) if entry.category_key

    terms = entry.type == "Equipment" ? EquipmentTerms : ExperienceTerms
    terms.new(reported_names(entry.type)).include?(entry.name)
  end

  def reported_names(type)
    case type
    when "Skill" then ExperienceCategories.matching_names(type, ExperienceCategories.profile_keys(@profile, type)) + @profile.reported_skills
    when "Equipment" then ExperienceCategories.matching_names(type, @profile.equipment_family_keys) + @profile.reported_equipment
    else
      @profile.occupations.filter_map do |occupation|
        # Compatibility for broad role families selected during the earlier rollout.
        terms = [ occupation.name, *ExperienceV1::ROLE_TERMS.fetch(occupation.category_key, []) ]
        occupation.name if terms.any? { |term| mentioned?(term) }
      end
    end
  end

  def mentioned?(name)
    return false if name.blank?

    text = "#{@job.title} #{@job.plain_description}"
    text.match?(/(?<![[:alnum:]])#{Regexp.escape(name)}(?![[:alnum:]])/i)
  end
end
