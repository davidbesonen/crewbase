class Usr::CrewMembersController < ApplicationController
  before_action :set_company
  before_action :set_member, only: [ :show, :edit, :update, :destroy, :invitation ]

  def index
    scope = @company.crew_members.includes(profile: :user).order(:last_name, :first_name)
    if params[:q].present?
      term = "%#{CrewMember.sanitize_sql_like(params[:q].to_s.strip)}%"
      scope = scope.where("concat_ws(' ', first_name, last_name, email, phone, phone_key, role, department, city, state, equipment_text, skills_text) ILIKE ?", term)
    end
    @pagy, @members = pagy(scope)
  end

  def show
    @invitation_url = crew_claim_url(@member.generate_token_for(:claim)) if @member.invitation_active?
  end

  def new
    @member = @company.crew_members.new
  end

  def create
    @member = @company.crew_members.new(member_params)
    if @member.save
      redirect_to usr_company_crew_member_path(@company, @member), notice: "Crew member added to your private roster."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @member.update(member_params)
      redirect_to usr_company_crew_member_path(@company, @member), notice: "Roster details updated. Their personal KnowShow profile is unchanged."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @member.destroy!
    redirect_to usr_company_crew_members_path(@company), notice: "Removed from your roster. Their account and work history are unchanged."
  end

  def invitation
    return redirect_to usr_company_crew_member_path(@company, @member), alert: "This profile has already been claimed." if @member.profile_id?

    @member.invitation_token!
    redirect_to usr_company_crew_member_path(@company, @member), status: :see_other
  end

  private

  def set_company
    @company = current_user.owned_companies.find(params[:company_id])
    @entitlement = CompanyPlanEntitlement.new(@company)
    response.headers["Cache-Control"] = "private, no-store"
  end

  def set_member
    @member = @company.crew_members.includes(profile: :user).find(params[:id])
  end

  def member_params = params.require(:crew_member).permit(*CrewMember::FIELDS)
end
