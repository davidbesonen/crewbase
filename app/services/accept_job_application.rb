# Employer decisions create offers; only RespondToJobOffer confirms bookings.
class AcceptJobApplication
  def initialize(application:, reviewer:, crew_position: nil, attributes: {})
    @application, @reviewer, @crew_position, @attributes = application, reviewer, crew_position, attributes
  end

  def call
    IssueJobOffer.new(application: @application, sender: @reviewer, position: @crew_position, attributes: @attributes).call
  end
end
