class ProfileFormCatalog
  attr_reader :profile

  def initialize(profile)
    @profile = profile
  end

  def occupations
    Occupation.includes(:industries).order(:name)
  end

  def profile_occupations
    profile.occupations
  end

  def skills
    assignments_for(Skill)
  end

  def profile_skills
    profile.skills
  end

  def equipment
    assignments_for(Equipment)
  end

  def profile_equipment
    profile.equipment
  end

  private

  def assignments_for(model)
    model.includes(:industries, :occupations)
      .joins(:occupation_assignments)
      .where(
        occupation_assignments: {
          occupation_id: profile_occupations.select(:id),
          assignable_type: model.name
        }
      )
      .distinct
      .order(:name)
  end
end
