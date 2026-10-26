# Suggestions are prompts for member confirmation, never recommendation inputs.
# General work language is bounded; no product/brand registry is maintained.
class ExperienceCategorySuggestions
  Suggestion = Data.define(:field, :category, :evidence)
  def initialize(profile:)
    @profile = profile
  end

  def results
    roles = @profile.occupations.map(&:name)
    suggestions(:capability_keys, "Skill", @profile.reported_skills + roles) +
      suggestions(:equipment_family_keys, "Equipment", @profile.reported_equipment + roles)
  end

  private

  def suggestions(field, type, entries)
    confirmed = ExperienceCategories.profile_keys(@profile, type)
    proposed = ExperienceCategories.selectable(type).filter_map do |category|
      next if ExperienceCategories.covers?(type, confirmed, category.key)

      evidence = entries.find do |entry|
        category.terms.any? { |term| entry.match?(/(?<![[:alnum:]])#{Regexp.escape(term)}(?![[:alnum:]])/i) }
      end
      Suggestion.new(field:, category:, evidence:) if evidence
    end
    keys = ExperienceCategories.most_specific(type, proposed.map { |suggestion| suggestion.category.key })
    proposed.select { |suggestion| keys.include?(suggestion.category.key) }
  end
end
