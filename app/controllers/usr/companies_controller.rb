class Usr::CompaniesController < ApplicationController
  before_action :set_owned_company, only: [ :edit, :update, :destroy ]

  def index
    companies_scope = visible_companies.includes(:industries, :jobs, :locations)

    @industries = Industry.order(:name)
    @q = companies_scope.ransack(params[:q])
    @pagy, @companies = pagy(@q.result(distinct: true).order(created_at: :desc, name: :asc))
  end

  def search
    query = params[:q].to_s.strip
    companies = if query.present?
      visible_companies
        .where("name ILIKE ?", "%#{Company.sanitize_sql_like(query)}%")
        .order(:name)
        .limit(8)
    else
      Company.none
    end

    render json: companies.map { |company|
      {
        id: company.id,
        name: company.name,
        avatar_url: company.image_url,
        initial: company.name.first&.upcase || "C"
      }
    }
  end

  def new
    @company = Company.new
    @company.locations.build if @company.locations.empty?
    @current_page = params[:current_page].presence || "company_plan_selection"
    @plans = Plan.active
    @industries = Industry.order(:name)
    @selected_plan_id = params[:plan_id]
    @selected_industry_ids = []
    @can_fill_mock_company_data = current_user.owned_companies.exists?
  end

  def create
    @company = Company.new(company_params.except(:locations_attributes))
    plan_id = params[:plan_id]
    plan = Plan.active.find_by(id: plan_id) if plan_id.present?

    if plan_id.present? && plan.blank?
      @company.errors.add(:base, "Plan is not available.")
      prepare_new_company_form(plan_id)
      render :new, status: :unprocessable_entity
    elsif @company.valid?
      Company.transaction do
        @company.save!
        location = find_or_create_location
        @company.locations << location if location && !@company.locations.include?(location)
        CompanyPlan.create!(company: @company, plan:, status: local_mock_company? ? "active" : "incomplete") if plan.present?
        CompanyAssignment.create!(company: @company, user: current_user, role: "owner")
      end

      redirect_after_company_creation(plan)
    else
      prepare_new_company_form(plan_id)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @plan = @company.plans.first
    # @company.locations.build if @company.locations.empty?
    @current_page = "company_details_form"
    @plans = Plan.active
    @industries = Industry.order(:name)
    @selected_plan_id = params[:plan_id]
    @selected_industry_ids = @company.industry_ids
  end

  def update
    if @company.update(company_params.except(:locations_attributes))
      location = find_or_create_location
      @company.locations << location if location && !@company.locations.include?(location)
      redirect_to usr_company_path(@company), notice: "Company updated successfully!"
    else
      @current_page = "company_details_form"
      @plan = @company.plans.first
      @industries = Industry.order(:name)
      @selected_industry_ids = @company.industry_ids
      render :edit, status: :unprocessable_entity
    end
  end

  def show
    @company = visible_companies.find(params[:id])
    @entitlement = CompanyPlanEntitlement.new(@company)
    @company_plan = @company.company_plans.includes(:plan).order(created_at: :desc, id: :desc).first&.plan
    @ratings = @company.ratings
    @jobs = @company.jobs.published.includes(:project).order(created_at: :desc)
    @job_applications = if @company.is_owner?(current_user)
      JobApplication
        .includes(:profile, { profile: :user }, job: :company)
        .joins(:job)
        .where(jobs: { company_id: @company.id })
        .order(created_at: :desc)
    else
      JobApplication.none
    end
  end

  def destroy
    @company.destroy
    redirect_to usr_dashboards_path, notice: "Company deleted successfully!"
  end

  def previous_form
    @page_order = [ "company_plan_selection", "company_details_form" ]
    @current_page = params[:current_page] || "company_plan_selection"
    current_page_index = @page_order.index(@current_page) || 0
    @previous_page = @page_order[current_page_index - 1] unless current_page_index.zero?
  end

  def next_form
    @page_order = [ "company_plan_selection", "company_details_form" ]
    @current_page = params[:current_page] || "company_plan_selection"
    current_page_index = @page_order.index(@current_page) || 0
    @next_page = @page_order[current_page_index + 1]
    @selected_plan_id = params[:plan_id]
    @plan = Plan.find_by(id: @selected_plan_id) if @selected_plan_id.present?
    @company = Company.new
    @company.locations.build if @company.locations.empty?
  end

  private

  def visible_companies
    Company.where(
      "companies.is_public = ? OR EXISTS (" \
        "SELECT 1 FROM company_assignments " \
        "WHERE company_assignments.company_id = companies.id " \
        "AND company_assignments.user_id = ?" \
      ")",
      true,
      current_user.id
    )
  end

  def prepare_new_company_form(selected_plan_id)
    @company.locations.build if @company.locations.empty?
    @current_page = "company_details_form"
    @plans = Plan.active
    @industries = Industry.order(:name)
    @selected_plan_id = selected_plan_id
    @plan = Plan.find_by(id: @selected_plan_id) if @selected_plan_id.present?
    @selected_industry_ids = @company.industry_ids
    @can_fill_mock_company_data = current_user.owned_companies.exists?
  end

  def set_owned_company
    @company = Company.joins(:company_assignments)
      .find_by!(
        id: params[:id],
        company_assignments: { user_id: current_user.id, role: "owner" }
      )
  end

  def company_params
    params.require(:company).permit(
      :name,
      :description,
      :website_url,
      :contact_email,
      :contact_phone,
      :linkedin_url,
      :twitter_handle,
      :instagram_handle,
      :facebook_url,
      :youtube_url,
      :tiktok_handle,
      :founded_at,
      :is_public,
      :file,
      :image,
      industry_ids: [],
      locations_attributes: [ :id, :address_line_1, :address_line_2, :city, :state, :zip_code, :country ]
    )
  end

  def find_or_create_location
    locations_attributes = company_params.fetch(:locations_attributes, {}).values.first
    return unless locations_attributes.present?

    attrs = locations_attributes.to_h.symbolize_keys.slice(
      :address_line_1,
      :address_line_2,
      :city,
      :state,
      :zip_code,
      :country
    ).transform_values(&:presence).compact

    return if attrs.empty?

    Location.find_or_create_by(attrs)
  end

  def redirect_after_company_creation(plan)
    return redirect_to usr_company_path(@company), notice: "Company created successfully!" unless plan
    return redirect_to usr_company_path(@company), notice: "Mock company created with local beta billing." if local_mock_company?

    session = StripeCompanyCheckout.new(
      company: @company,
      owner: current_user,
      plan:,
      interval: params[:billing_interval].presence || "monthly",
      success_url: usr_company_plan_url(@company, checkout: "success", session_id: "{CHECKOUT_SESSION_ID}"),
      cancel_url: usr_company_plan_url(@company, checkout: "cancelled")
    ).call
    redirect_to session.url, allow_other_host: true
  rescue StripeCompanyCheckout::InvalidSelection => error
    redirect_to usr_company_plan_path(@company), alert: "Company created. #{error.message}"
  end

  def local_mock_company?
    return @local_mock_company if defined?(@local_mock_company)

    @local_mock_company = Rails.env.local? && params[:mock_company] == "1" && current_user.owned_companies.exists?
  end
end
