class AcceptJobApplication
  Result = Data.define(:success?, :error)

  attr_reader :application, :reviewer, :crew_position

  def initialize(application:, reviewer:, crew_position: nil)
    @application = application
    @reviewer = reviewer
    @crew_position = crew_position
  end

  def call
    validation_error = position_validation_error
    return failure(validation_error) if validation_error

    JobApplication.transaction do
      if application.job.multi_position?
        crew_position.with_lock do
          return failure("That position is already fully staffed.") unless position_has_room?

          crew_position.crew_assignments.create!(profile: application.profile)
          accept_application!
        end
      else
        accept_application!
      end
    end

    success
  rescue ActiveRecord::RecordInvalid => error
    failure(error.record.errors.full_messages.to_sentence)
  end

  private

  def position_validation_error
    return unless application.job.multi_position?
    return "Select a position for this gig." unless crew_position
    return if crew_position.job_id == application.job_id

    "That position does not belong to this gig."
  end

  def position_has_room?
    crew_position.crew_assignments.count < crew_position.headcount
  end

  def accept_application!
    application.update!(
      status: :accepted,
      reviewed_at: Time.current,
      reviewed_by: reviewer.id,
      decision_at: Time.current
    )
  end

  def success
    Result.new(success?: true, error: nil)
  end

  def failure(error)
    Result.new(success?: false, error:)
  end
end
