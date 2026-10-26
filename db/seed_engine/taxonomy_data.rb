require_relative "../catalogs/occupations_v2"

module SeedEngineTaxonomyData
  def create_occupations
    InstallOccupationCatalog.new.call
    OccupationsV2::BY_INDUSTRY.each do |industry_name, names|
      industry = Industry.find_by!(name: industry_name)
      Occupation.where(category_key: nil, name: names).find_each do |occupation|
        occupation.industry_assignments.find_or_create_by!(industry: industry)
      end
    end
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
