module SeedEngineTaxonomyData
  def create_occupations
    InstallOccupationCatalog.new.call
  end

  # Compatibility with old seed invocations. Skills/equipment now belong to
  # individual profiles and jobs; no global inventory is generated.
  def create_brands
  end

  def create_skills
  end

  def create_equipment
  end
end
