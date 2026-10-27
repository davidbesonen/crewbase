class Usr::VenuesController < ApplicationController
  before_action :set_company
  before_action :set_venue, only: [ :edit, :update, :destroy ]

  def index
    @venues = @company.venues.order(:name).to_a
  end

  def new
    @venue = @company.venues.new
  end

  def create
    @venue = @company.venues.new(venue_params)
    @venue.save ? redirect_to(usr_company_venues_path(@company), notice: "Venue saved for future gigs.") : render(:new, status: :unprocessable_entity)
  end

  def edit
  end

  def update
    if UpdateVenue.new(venue: @venue, actor: current_user, attributes: venue_params).call
      redirect_to usr_company_venues_path(@company), notice: "Venue updated. Confirmed crew on upcoming gigs are notified in KnowShow."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @venue.destroy!
    redirect_to usr_company_venues_path(@company), notice: "Venue removed. Existing gigs remain; review their venue details."
  end

  private

  def set_company
    @company = current_user.owned_companies.find(params[:company_id])
    @entitlement = CompanyPlanEntitlement.new(@company)
  end

  def set_venue = @venue = @company.venues.find(params[:id])
  def venue_params = params.require(:venue).permit(*Venue::FIELDS, :venue_catalog_entry_id)
end
