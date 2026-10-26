class ReviewJobApplication
  Result = Data.define(:success?, :error)

  def initialize(application:, reviewer:, status:)
    @application, @reviewer, @status = application, reviewer, status
  end

  def call
    @application.with_lock do
      return Result.new(success?: false, error: "You cannot review this application.") unless @application.reviewable_by?(@reviewer)
      return Result.new(success?: false, error: "Cancel the confirmed booking before changing this application.") if @application.accepted?
      return Result.new(success?: false, error: "Send an offer to confirm hiring.") unless (JobApplication.review_statuses - [ "accepted" ]).include?(@status)

      if @status == "rejected"
        @application.job_offers.pending.each do |offer|
          offer.update!(status: :withdrawn, responded_at: Time.current)
          Notification.create!(recipient: offer.profile.user, actor: @reviewer, notifiable: offer, kind: "job_offer", message: "Offer withdrawn: #{offer.role}")
          ProductEvent.record(user: @reviewer, name: "offer_withdrawn", subject: offer, event_key: "offer:#{offer.id}:offer_withdrawn")
        end
      end
      @application.update!(status: @status, reviewed_at: Time.current, reviewed_by: @reviewer.id,
        decision_at: @status == "rejected" ? Time.current : nil)
      Result.new(success?: true, error: nil)
    end
  end
end
