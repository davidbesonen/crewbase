require "digest"

class ImportVenueCatalog
  def initialize(rows: nil, source_path: Rails.root.join("public/data/us-venues.json"), cache: Rails.cache)
    @rows = rows
    @source_path = source_path
    @cache = cache
  end

  def call(force: false)
    return import(@rows) if @rows

    key = [ "venue-catalog-import-v1", Digest::SHA256.file(@source_path).hexdigest ]
    count = @cache.read(key) unless force
    return count if count && VenueCatalogEntry.count == count

    count = import(JSON.parse(File.read(@source_path)))
    @cache.write(key, count)
    count
  end

  private

  def import(rows)
    VenueCatalogEntry.transaction do
      rows.each_slice(1000) do |batch|
        entries = batch.map do |row|
          source = row.stringify_keys
          attributes = [ "source_key", *VenueCatalogEntry::LOCATION_FIELDS, "category", "latitude", "longitude" ].index_with { |key| source[key] }
          attributes.merge("search_text" => VenueCatalogEntry.search_text_for(attributes))
        end
        VenueCatalogEntry.upsert_all(entries, unique_by: :source_key)
      end
    end
    rows.size
  end
end
