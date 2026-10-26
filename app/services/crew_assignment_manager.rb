class CrewAssignmentManager
  def initialize(position:, profile:, assignment: nil, user:, attributes: {})
    @position, @profile, @assignment, @user, @attributes = position, profile, assignment, user, attributes
  end

  def call
    return false if @assignment || !@position.job.company.is_owner?(@user)
    return false unless JobCrewCandidateQuery.new(job: @position.job, user: @user).profiles.exists?(@profile.id)

    application = @position.job.job_applications.find_or_initialize_by(profile: @profile)
    IssueJobOffer.new(application:, sender: @user, position: @position, attributes: @attributes).call.success?
  end
end
