class OccupationCatalog
  def initialize(selected: [])
    @selected = selected.grep(Occupation)
  end

  def records(selected_ids: [])
    # Only explicitly saved selections may expose retired occupations. A URL or
    # submitted ID must not reintroduce an occupation from another market.
    Occupation.touring
      .or(Occupation.where(id: @selected.map(&:id))).order(:name)
  end
end
