class Usr::ProjectsController < ApplicationController
  before_action :set_company, only: [ :index, :new, :create ]
  before_action :set_project, only: [ :show, :edit, :update, :destroy, :archive, :unarchive ]

  def index
    projects = @company.projects.includes(:jobs).order(updated_at: :desc)
    @projects = projects.active
    @archived_projects = projects.archived
    @active_only = params[:view] == "active"
    if @active_only
      @projects = @projects.in_progress
      @archived_projects = Project.none
    end
  end

  def show
    @overview = ProjectStaffingOverview.new(project: @project)
    @jobs = @overview.jobs
    @workspace_view = params[:view].presence_in(%w[shows roles crew]) || (@project.multi_show? ? "shows" : "roles")
  end

  def new
    @project = @company.projects.new(project_type: :multi_show)
  end

  def create
    @project = @company.projects.new(project_params.merge(project_type: :multi_show))

    unless active_project_capacity_available?(@project)
      @project.errors.add(:base, active_project_limit_message)
      return render :new, status: :unprocessable_entity
    end

    if @project.save
      destination = case params[:next_step]
      when "post_job" then new_usr_company_job_path(@company, project_id: @project.id)
      when "add_shows" then new_usr_project_project_show_path(@project)
      else usr_project_path(@project)
      end
      redirect_to destination, notice: "Project created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    requested_status = project_params[:status]
    activates_project = @project.archived? || (!@project.status.in?(%w[planning active]) && requested_status.in?(%w[planning active]))
    if activates_project && capacity_enforced? && !@entitlement.within_limit?(:active_projects)
      @project.errors.add(:base, active_project_limit_message)
      return render :edit, status: :unprocessable_entity
    end

    if @project.update(project_params)
      redirect_to usr_project_path(@project), notice: "Project updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    company = @project.company
    RemoveProject.new(project: @project).call
    redirect_to usr_company_projects_path(company), notice: "Project deleted successfully."
  end

  def archive
    @project.archive!
    redirect_to usr_company_projects_path(@company), notice: "Project archived successfully."
  end

  def unarchive
    if capacity_enforced? && !@entitlement.within_limit?(:active_projects)
      return redirect_to usr_company_projects_path(@company), alert: active_project_limit_message
    end

    @project.restore!
    redirect_to usr_project_path(@project), notice: "Project restored successfully."
  end

  def select_company
    @companies = owned_companies.includes(:locations, :industries).order(:name).to_a
    @projects_by_company = Project.active.where(company: @companies)
      .order(updated_at: :desc, id: :desc)
      .group_by(&:company_id)
  end

  private

  def set_company
    @company = owned_companies.find(params[:company_id])
    @entitlement = CompanyPlanEntitlement.new(@company)
  end

  def set_project
    @project = Project.includes(:company).where(company: owned_companies).find(params[:id])
    @company = @project.company
    @entitlement = CompanyPlanEntitlement.new(@company)
  end

  def owned_companies
    current_user.owned_companies.distinct
  end

  def project_params
    params.require(:project).permit(:name, :description, :status, :starts_on, :ends_on)
  end

  def active_project_capacity_available?(project)
    !project.status.in?(%w[planning active]) || project_capacity.available?
  end

  def capacity_enforced?
    project_capacity.enforced?
  end

  def active_project_limit_message
    project_capacity.message
  end

  def project_capacity = @project_capacity ||= CompanyProjectCapacity.new(company: @company)
end
