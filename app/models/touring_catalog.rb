require Rails.root.join("db/catalogs/occupations_v2")

class TouringCatalog
  DATA = YAML.safe_load_file(Rails.root.join("config/touring.yml")).freeze

  def self.industry_name = DATA.fetch("industry")
  def self.retired_industries = DATA.fetch("retired_industries")
  def self.occupation_names = DATA.fetch("occupations")
  def self.category_keys(type) = DATA.fetch(type)
  def self.retired_occupation_names = OccupationsV2::BY_INDUSTRY.values.flatten.uniq - occupation_names
end
