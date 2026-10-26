class JobCrewSearch
  Result = Data.define(:recommendation, :availability) do
    delegate :profile, :job, :match_reason, :score, :rating, :relevant_years,
      :matched_skills_and_equipment, to: :recommendation
  end

  def initialize(job:, user:, occupation_id: nil, skill_id: nil, equipment_id: nil, skill_query: nil, equipment_query: nil, availability_state: nil)
    @skill_query = skill_query
    @equipment_query = equipment_query
    @job = job
    @user = user
    @occupation_id = occupation_id.presence&.to_i
    @skill_id = skill_id.presence&.to_i
    @equipment_id = equipment_id.presence&.to_i
    @legacy_skill_name = Skill.find_by(id: @skill_id)&.name if @skill_id
    @legacy_equipment_name = Equipment.find_by(id: @equipment_id)&.name if @equipment_id
    @availability_state = availability_state.presence&.to_sym
  end

  def results
    CrewRecommender.new(user:, jobs: [ job ], limit: nil).results.filter_map do |recommendation|
      next unless taxonomy_filters_match?(recommendation.profile)
      next unless personal_filters_match?(recommendation.profile)

      availability = ProfileJobAvailability.new(profile: recommendation.profile, job:).result
      next if availability_state && availability.state != availability_state

      Result.new(recommendation:, availability:)
    end
  end

  private

  attr_reader :job, :user, :occupation_id, :skill_id, :equipment_id, :availability_state

  def taxonomy_filters_match?(profile)
    association_includes?(profile.occupations, occupation_id) &&
      legacy_entry_matches?(skill_names(profile), skill_id, @legacy_skill_name) &&
      legacy_entry_matches?(equipment_names(profile), equipment_id, @legacy_equipment_name)
  end

  def personal_filters_match?(profile)
    (@skill_query.blank? || ExperienceTerms.new(skill_names(profile)).include?(@skill_query)) &&
      (@equipment_query.blank? || ExperienceTerms.new(equipment_names(profile)).include?(@equipment_query))
  end

  def skill_names(profile)
    ExperienceCategories.matching_names("Skill", ExperienceCategories.profile_keys(profile, "Skill")) + profile.reported_skills
  end

  def equipment_names(profile)
    ExperienceCategories.matching_names("Equipment", profile.equipment_family_keys) + profile.reported_equipment
  end

  def legacy_entry_matches?(values, requested_id, name)
    requested_id.blank? || (name.present? && ExperienceTerms.new(values).include?(name))
  end

  def association_includes?(records, requested_id)
    requested_id.blank? || records.any? { |record| record.id == requested_id }
  end
end
