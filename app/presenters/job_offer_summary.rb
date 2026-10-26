class JobOfferSummary
  attr_reader :offer

  def initialize(offer:, viewer_id:)
    @offer, @viewer_id = offer, viewer_id
  end

  def recipient?
    offer.profile.user_id == @viewer_id
  end

  def job
    offer.job_application.job
  end

  def state
    return "completed" if offer.accepted? && (offer.ends_at <= Time.current || job.completed?)
    return "archived" if offer.accepted? && job.archived?
    return "unavailable" if offer.pending? && job.conversation_archived?

    offer.effective_status
  end

  def label
    return recipient? ? "Needs your reply" : "Awaiting crew" if state == "pending"
    return "Confirmed" if state == "accepted"

    state.humanize
  end

  def status_class
    case state
    when "pending" then "status-warning"
    when "accepted", "completed" then "status-available"
    else "status-unavailable"
    end
  end

  def action_label
    return "Review offer" if state == "pending" && recipient?
    return "View booking" if offer.accepted?

    "View offer"
  end

  def expiring_soon?
    state == "pending" && offer.expires_at.present? && offer.expires_at <= 48.hours.from_now
  end
end
