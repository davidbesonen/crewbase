class CrewAssignmentManager
  def initialize(position:, profile:, assignment: nil, user:)
    @position = position
    @profile = profile
    @assignment = assignment
    @user = user
  end

  def call
    return failure("is not an eligible candidate") unless eligible?

    position.with_lock do
      record.profile = profile
      record.save
    end
  end

  private

  attr_reader :position, :profile, :assignment, :user

  def record
    @record ||= assignment || position.crew_assignments.build
  end

  def eligible?
    JobCrewCandidateQuery.new(job: position.job, user:).profiles.exists?(profile.id)
  end

  def failure(message)
    record.errors.add(:profile, message)
    false
  end
end
