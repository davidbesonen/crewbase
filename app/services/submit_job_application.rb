class SubmitJobApplication
  def initialize(application:, invitation: nil)
    @application = application
    @invitation = invitation
  end

  def call
    JobApplication.transaction do
      application.save!
      invitation&.accept!
      ProductEvent.record(user: application.profile.user, name: "application_submitted", subject: application, event_key: application.id)
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  private

  attr_reader :application, :invitation
end
