class ProfileExperienceSearch
  def initialize(scope:, skills_query: nil, equipment_query: nil)
    @scope = scope
    @skills_query = skills_query
    @equipment_query = equipment_query
  end

  def results
    scope = filter(@scope, @skills_query, :skills_text, SkillAssignment, :skill)
    filter(scope, @equipment_query, :equipment_text, EquipmentAssignment, :equipment)
  end

  private

  def filter(scope, query, field, assignments, association)
    return scope if query.blank?

    pattern = "%#{ActiveRecord::Base.sanitize_sql_like(query.to_s.strip)}%"
    table = association == :skill ? "skills" : "equipment"
    alias_pattern = EquipmentTerms.search_pattern(query) if association == :equipment
    operator = alias_pattern ? "~*" : "ILIKE"
    pattern = alias_pattern || pattern
    legacy_ids = assignments.joins(association).where("#{table}.name #{operator} ?", pattern).select(:profile_id)
    matching = scope.where("profiles.#{field} #{operator} ?", pattern)
      .or(scope.where(field => nil).where(id: legacy_ids))
    type = association == :skill ? "Skill" : "Equipment"
    category_field = ExperienceCategories::PROFILE_FIELDS.key(type)
    keys = ExperienceCategories.search_keys(type, query)
    return matching if keys.empty?

    matching = matching.or(scope.where("profiles.#{category_field} && ARRAY[?]::varchar[]", keys))
    return matching unless type == "Skill"

    core_ids = OccupationAssignment.joins(:occupation).where(assignable_type: "Profile")
      .where("LOWER(occupations.name) IN (?)", OccupationExperienceCategories.names_covering(keys)).select(:assignable_id)
    matching.or(scope.where(id: core_ids))
  end
end
