class Usr::Company::CrewRosterUploadComponent < ApplicationComponent
  def initialize(company:, can_browse:)
    @company, @can_browse = company, can_browse
  end
end
