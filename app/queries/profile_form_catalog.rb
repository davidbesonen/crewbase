class ProfileFormCatalog
  attr_reader :profile

  def initialize(profile)
    @profile = profile
  end

  def occupations
    OccupationCatalog.new(selected: profile_occupations).records
  end

  def profile_occupations
    profile.occupations
  end
end
