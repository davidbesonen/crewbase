class OccupationCatalog
  def initialize(selected: [])
    @selected = selected.grep(Occupation)
  end

  def records(selected_ids: [])
    selected_ids = Array(selected_ids) + @selected.map(&:id)
    Occupation.where(category_key: nil).or(Occupation.where(id: selected_ids)).order(:name)
  end
end
