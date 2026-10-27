class ImportVenueCatalog
  def initialize(rows: nil)
    @rows = rows
  end

  def call
    rows = @rows || JSON.parse(Rails.root.join("public/data/us-venues.json").read)
    rows.each_slice(1000) do |batch|
      entries = batch.map do |row|
        source = row.stringify_keys
        attributes = [ "source_key", *VenueCatalogEntry::LOCATION_FIELDS, "category", "latitude", "longitude" ].index_with { |key| source[key] }
        attributes.merge("search_text" => VenueCatalogEntry.search_text_for(attributes))
      end
      VenueCatalogEntry.upsert_all(entries, unique_by: :source_key)
    end
    rows.size
  end
end
