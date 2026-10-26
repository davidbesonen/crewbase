require Rails.root.join("db/catalogs/occupations_v2")

class InstallOccupationCatalog
  def call
    OccupationsV2.install!
  end
end
