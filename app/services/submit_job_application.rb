class SubmitJobApplication
  def initialize(application:, invitation: nil)
    @application = application
    @invitation = invitation
  end

  def call
    JobApplication.transaction do
      application.save!
      invitation&.accept!
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  private

  attr_reader :application, :invitation
end
