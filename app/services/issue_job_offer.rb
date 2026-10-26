class IssueJobOffer
  Result = Data.define(:success?, :offer, :error)

  def initialize(application:, sender:, attributes:, position: nil)
    @application, @sender, @attributes, @position = application, sender, attributes, position
  end

  def call
    application.job.with_lock do
      application.profile.with_lock do
        application.new_record? ? issue_new_application : application.with_lock { issue }
      end
    end
  rescue ActiveRecord::RecordInvalid => error
    failure(error.record.errors.full_messages.to_sentence)
  end

  private

  attr_reader :application, :sender, :attributes, :position

  def issue_new_application
    result = nil
    JobApplication.transaction(requires_new: true) do
      application.save!
      result = issue
      raise ActiveRecord::Rollback unless result.success?
    end
    result
  end

  def issue
    return failure("You cannot offer this job.") unless application.reviewable_by?(sender)
    return failure("This person is not available for new offers.") if application.profile.user.restricted_at? || UserBlock.between?(sender, application.profile.user)
    return failure("This job is on an administrative hold.") if application.job.on_hold?
    return failure("This job has ended.") if application.job.conversation_archived?
    return failure("This booking is already confirmed. Cancel it before changing terms.") if application.accepted?
    if application.job.multi_position? && (!position || !application.job.crew_positions.exists?(position.id))
      return failure("Select a position belonging to this gig.")
    end

    offer = application.job_offers.build(attributes.merge(profile: application.profile, sender:, crew_position: position))
    return failure(offer.errors.full_messages.to_sentence, offer) unless offer.valid?

    application.job_offers.pending.each do |previous|
      previous.update!(status: :withdrawn, responded_at: Time.current)
      ProductEvent.record(user: sender, name: "offer_withdrawn", subject: previous, event_key: "offer:#{previous.id}:offer_withdrawn")
    end
    offer.save!
    application.update!(status: :shortlisted, reviewed_at: Time.current, reviewed_by: sender.id, decision_at: nil)
    Notification.create!(recipient: application.profile.user, actor: sender, notifiable: offer,
      kind: "job_offer", message: "#{application.job.company.name} sent you an offer for #{offer.role}.")
    NotificationDelivery.enqueue!(recipient: application.profile.user, kind: "job_offer", deduplication_key: "offer:#{offer.id}:pending", payload: { offer_id: offer.id })
    ProductEvent.record(user: sender, name: "offer_sent", subject: offer, event_key: "offer:#{offer.id}:sent")
    Result.new(success?: true, offer:, error: nil)
  end

  def failure(error, offer = nil)
    Result.new(success?: false, offer:, error:)
  end
end
