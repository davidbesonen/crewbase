class JobCrewSearch
  Result = Data.define(:recommendation, :availability) do
    delegate :profile, :job, :match_reason, :score, :rating, :relevant_years,
      :matched_skills_and_equipment, to: :recommendation
  end

  def initialize(job:, user:, occupation_id: nil, skill_id: nil, equipment_id: nil, availability_state: nil)
    @job = job
    @user = user
    @occupation_id = occupation_id.presence&.to_i
    @skill_id = skill_id.presence&.to_i
    @equipment_id = equipment_id.presence&.to_i
    @availability_state = availability_state.presence&.to_sym
  end

  def results
    CrewRecommender.new(user:, jobs: [ job ], limit: nil).results.filter_map do |recommendation|
      next unless taxonomy_filters_match?(recommendation.profile)

      availability = ProfileJobAvailability.new(profile: recommendation.profile, job:).result
      next if availability_state && availability.state != availability_state

      Result.new(recommendation:, availability:)
    end
  end

  private

  attr_reader :job, :user, :occupation_id, :skill_id, :equipment_id, :availability_state

  def taxonomy_filters_match?(profile)
    association_includes?(profile.occupations, occupation_id) &&
      association_includes?(profile.skills, skill_id) &&
      association_includes?(profile.equipment, equipment_id)
  end

  def association_includes?(records, requested_id)
    requested_id.blank? || records.any? { |record| record.id == requested_id }
  end
end
