class VenueCatalogSearch
  def initialize(query:)
    @query = query.to_s.first(120).parameterize(separator: " ")
  end

  def results
    return [] if @query.length < 2
    entries = VenueCatalogEntry.all
    @query.split.first(8).each { |term| entries = entries.where("search_text LIKE ?", "%#{term}%") }
    entries.order(:name, :id).limit(12).map(&:search_result)
  end
end
