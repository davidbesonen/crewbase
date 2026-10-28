class Usr::JobInvitationInboxComponent < ApplicationComponent
  def initialize(received:, sent:, company: nil, status: nil)
    @received = received
    @sent = sent
    @company = company
    @status = status
  end

  private

  attr_reader :received, :sent, :company, :status

  def sent_heading = status ? "#{status.humanize} Invitations" : "Sent"

  def status_class(invitation)
    case invitation.status
    when "accepted" then "text-bg-success"
    when "declined" then "text-bg-secondary"
    else "text-bg-warning"
    end
  end

  def recipient_name(invitation)
    invitation.profile&.user&.full_name.presence || invitation.email
  end
end
