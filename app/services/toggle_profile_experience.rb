# Compatibility for a previously opened catalog picker. The active personal
# entries change; historical assignment records remain available for reference.
class ToggleProfileExperience
  def initialize(profile:, entry:)
    @profile = profile
    @entry = entry
  end

  def call
    field, values = if @entry.is_a?(Skill)
      [ :skills_text, @profile.reported_skills ]
    else
      [ :equipment_text, @profile.reported_equipment ]
    end
    terms = ExperienceTerms.new(values)
    values = if terms.include?(@entry.name)
      values.reject { |value| ExperienceTerms.key(value) == ExperienceTerms.key(@entry.name) }
    else
      values + [ @entry.name ]
    end
    @profile.update(field => values.join("\n"))
  end
end
