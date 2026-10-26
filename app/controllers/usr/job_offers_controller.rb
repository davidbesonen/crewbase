class Usr::JobOffersController < ApplicationController
  before_action :set_offer, only: [ :show, :update, :calendar ]
  before_action :set_application, only: [ :new, :create ]

  def index
    @inbox = JobOfferInbox.new(user: current_user, view: params[:view], query: params[:q])
    @pagy, @offers = pagy(@inbox.results)
    @offer_summaries = @offers.map { |offer| JobOfferSummary.new(offer:, viewer_id: current_user.id) }
  end

  def calendar
    raise ActiveRecord::RecordNotFound unless @offer.accepted?

    response.headers["Cache-Control"] = "private, no-store"
    send_data BookingCalendar.new(offer: @offer, url: usr_job_offer_url(@offer)).to_ical,
      type: "text/calendar; charset=utf-8", disposition: "attachment", filename: "crewbase-booking-#{@offer.id}.ics"
  end

  def new
    pay_source = @position || @application.job
    @offer = @application.job_offers.build(role: pay_source.title, starts_at: @application.job.starts_at,
      ends_at: @application.job.ends_at, rate: pay_source.pay_min, currency: "USD", pay_unit: pay_source.pay_period || "daily")
  end

  def create
    result = IssueJobOffer.new(application: @application, sender: current_user, position: @position, attributes: offer_params.to_h).call
    if result.success?
      redirect_to usr_job_offer_path(result.offer), notice: "Offer sent. The worker must accept before the booking is confirmed."
    else
      @offer = result.offer || @application.job_offers.build(offer_params)
      flash.now[:alert] = result.error
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @owner_view = @offer.job_application.reviewable_by?(current_user)
    @recipient_view = @offer.recipient?(current_user)
    @availability = ProfileJobAvailability.new(profile: @offer.profile, job: @offer).result
  end

  def update
    result = RespondToJobOffer.new(offer: @offer, user: current_user, action: params[:decision].to_s, reason: params[:reason].to_s.strip).call
    redirect_to usr_job_offer_path(@offer), (result.success? ? { notice: "Offer updated." } : { alert: result.error })
  end

  private

  def set_offer
    @offer = JobOffer.visible_to(current_user).includes({ profile: :user }, :sender, job_application: { job: [ :company, :locations ] }).find(params[:id])
  end

  def set_application
    if params[:job_application_id].present?
      @application = JobApplication.joins(job: :company).where(jobs: { company_id: current_user.owned_companies.select(:id) }).find(params[:job_application_id])
      @position = @application.job.crew_positions.find(params[:crew_position_id]) if params[:crew_position_id].present?
    else
      @position = CrewPosition.joins(job: :company).where(jobs: { company_id: current_user.owned_companies.select(:id) }).find(params[:crew_position_id])
      profile = JobCrewCandidateQuery.new(job: @position.job, user: current_user).profiles.find(params[:profile_id])
      @application = @position.job.job_applications.find_or_initialize_by(profile:)
    end
    raise ActiveRecord::RecordNotFound if UserBlock.between?(current_user, @application.profile.user)

    @positions = @application.job.crew_positions.order(:title)
  end

  def offer_params
    params.require(:job_offer).permit(:role, :starts_at, :ends_at, :rate, :currency, :pay_unit, :terms, :expires_at)
  end
end
