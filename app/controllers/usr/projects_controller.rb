class Usr::ProjectsController < ApplicationController
  before_action :set_company, only: [ :index, :new, :create ]
  before_action :set_project, only: [ :show, :edit, :update, :destroy, :archive, :unarchive ]

  def index
    projects = @company.projects.includes(:jobs).order(updated_at: :desc)
    @projects = projects.active
    @archived_projects = projects.archived
  end

  def show
    @jobs = @project.jobs.includes(:locations, :job_applications).order(created_at: :desc)
  end

  def new
    @project = @company.projects.new
  end

  def create
    @project = @company.projects.new(project_params)

    unless active_project_capacity_available?(@project)
      @project.errors.add(:base, active_project_limit_message)
      return render :new, status: :unprocessable_entity
    end

    if @project.save
      redirect_to usr_project_path(@project), notice: "Project created successfully."
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
    @project.destroy!
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
    @companies = owned_companies.order(:name)
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
    return true unless project.status.in?(%w[planning active]) && capacity_enforced?

    @entitlement.within_limit?(:active_projects)
  end

  def capacity_enforced?
    @entitlement.current_plan&.data&.key?("projects_limit")
  end

  def active_project_limit_message
    "#{@entitlement.current_plan.name} plan allows #{@entitlement.limit(:active_projects)} active projects. Archive or complete a project, or upgrade your plan."
  end
end
