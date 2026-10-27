class Usr::JobPlacementComponent < ApplicationComponent
  def initialize(company:, projects:, gigs:, values:)
    @company, @projects, @gigs, @values = company, projects, gigs, values
  end

  def choices
    [ [ "standalone", "A Standalone Job", "One role with its own dates, outside a larger crew gig or Project.", "person-workspace" ],
      [ "gig", "Another Role In An Existing Gig", "Add a role and headcount to a gig you have already set up. Its schedule and crew stay together.", "people" ],
      [ "project", "A Role On A Tour / Festival Project", "Choose the Project, then decide whether this role covers the whole run or selected shows and cities.", "map" ] ]
  end
end
