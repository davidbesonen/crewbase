class RespondToJobOffer
  Result = Data.define(:success?, :error)

  def initialize(offer:, user:, action:, reason: nil)
    @offer, @user, @action, @reason = offer, user, action, reason
  end

  def call
    return failure("You cannot respond to this offer.") unless authorized?
    # Lock the job for shared capacity and the profile for cross-job conflicts.
    offer.job.with_lock do
      offer.profile.with_lock do
        offer.job_application.with_lock do
          offer.with_lock { transition }
        end
      end
    end
  rescue ActiveRecord::RecordInvalid => error
    failure(error.record.errors.full_messages.to_sentence)
  end

  private

  attr_reader :offer, :user, :action, :reason

  def authorized?
    case action
    when "accept", "decline" then offer.recipient?(user)
    when "withdraw" then offer.job_application.reviewable_by?(user)
    when "cancel" then offer.recipient?(user) || offer.job_application.reviewable_by?(user)
    else false
    end
  end

  def transition
    return cancel if action == "cancel"
    target = { "accept" => "accepted", "decline" => "declined", "withdraw" => "withdrawn" }.fetch(action)
    return success if offer.status == target
    if offer.effective_status == "expired"
      offer.update!(status: :expired, responded_at: Time.current) if offer.pending?
      return failure("This offer has expired.")
    end
    return failure("This offer is no longer pending.") unless offer.pending?
    if action == "accept"
      error = acceptance_error
      return failure(error) if error
      confirm_booking!
    end
    offer.update!(status: target, responded_at: Time.current)
    record_event("offer_#{target}")
    notify("Offer #{target}: #{offer.role}")
    success
  end

  def acceptance_error
    return "This job has ended." if offer.job.conversation_archived? || offer.ends_at <= Time.current
    return "You have a calendar conflict or confirmed booking on these dates." if BookingConflicts.new(profile: offer.profile, schedule: offer, excluding_job_id: offer.job.id).dates.any?
    if offer.job.multi_position?
      return "This position is no longer available." unless offer.crew_position&.job_id == offer.job.id
      return "This position is already fully staffed." if offer.crew_position.crew_assignments.count >= offer.crew_position.headcount
    elsif offer.job.job_applications.accepted.where.not(id: offer.job_application_id).exists?
      return "This role is already filled."
    end
    nil
  end

  def confirm_booking!
    offer.crew_position.crew_assignments.create!(profile: offer.profile, job_offer: offer) if offer.job.multi_position?
    offer.job_application.update!(status: :accepted, decision_at: Time.current)
    JobAcceptanceConversation.new(application: offer.job_application, reviewer: offer.sender).call
  end

  def cancel
    return success if offer.cancelled?
    return failure("Only a confirmed booking can be cancelled.") unless offer.accepted?
    return failure("Completed work cannot be cancelled.") if offer.job.conversation_archived? || offer.ends_at <= Time.current
    return failure("Add a reason for cancellation.") if reason.blank?
    offer.update!(status: :cancelled, cancelled_at: Time.current, cancelled_by: user, cancellation_reason: reason)
    offer.crew_assignment&.destroy!
    offer.job_application.update!(status: :withdrawn, decision_at: Time.current)
    record_event("booking_cancelled")
    notify("Booking cancelled: #{offer.role}")
    success
  end

  def notify(message)
    recipient = offer.recipient?(user) ? offer.sender : offer.profile.user
    Notification.create!(recipient:, actor: user, notifiable: offer, kind: "job_offer", message:)
  end

  def record_event(name)
    ProductEvent.record(user:, name:, subject: offer, event_key: "offer:#{offer.id}:#{name}")
  end

  def success
    Result.new(success?: true, error: nil)
  end

  def failure(error)
    Result.new(success?: false, error:)
  end
end
