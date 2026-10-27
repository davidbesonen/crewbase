class Usr::CrewRosterComponent < ApplicationComponent
  def initialize(company:, members:, query: nil)
    @company, @members, @query = company, members, query
  end
end
