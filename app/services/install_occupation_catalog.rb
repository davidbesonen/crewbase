class InstallOccupationCatalog
  def call
    Industry.transaction do
      industry = Industry.find_or_create_by!(name: TouringCatalog.industry_name)
      TouringCatalog.occupation_names.each do |name|
        occupation = Occupation.find_or_create_by!(name:, category_key: nil)
        occupation.industry_assignments.find_or_create_by!(industry:)
      end
    end
  end
end
