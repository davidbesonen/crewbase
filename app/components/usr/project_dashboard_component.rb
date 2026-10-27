# frozen_string_literal: true

class Usr::ProjectDashboardComponent < ApplicationComponent
  extend Dry::Initializer

  option :project
  option :jobs
  option :workspace_view, default: proc { "roles" }
  option :show_count, default: proc { 0 }

  def posting_count
    jobs.size
  end

  def open_posting_count
    jobs.count { |job| job.published? && job.is_active? }
  end

  def application_count
    jobs.sum { |job| job.job_applications.size }
  end

  def add_job_path
    return new_usr_company_job_path(project.company, project_id: project.id, audience: "invite_only") if project.multi_show?
    new_usr_company_job_path(project.company, project_id: project.id)
  end

  def postings_label = project.multi_show? ? "Roles & Postings" : "Job Postings"
  def add_job_label = project.multi_show? ? "Post A Job" : "Add Job Posting"
  def add_shows_label = project.multi_show? ? "Add Multiple Shows" : "Create Tour Stops"
  def open_postings_label = project.multi_show? ? "Active Postings" : "Open Postings"
  def empty_heading = project.multi_show? ? "Add Your First Role" : "Create The First Job Posting"
  def empty_hint = project.multi_show? ? "Add your shows, then post a role for the entire run or selected cities." : "No job postings yet. Add a role to start recruiting and tracking applicants for this project."
  def postings_hint = project.multi_show? ? "Each posting describes a crew need, not another event. Set the shows it covers; everyone hired through it shares those shows." : "Create roles, review applicants, and keep each posting moving."
  def job_status_label(job) = job.invite_only? && job.published? ? "Active · Invite only" : job.status.humanize
  def staffing_path(job) = job.multi_position? ? usr_job_crew_path(job) : usr_company_staffing_path(project.company, project_id: project.id, from: job.starts_at&.to_date || Date.current)
  def primary_staffing_label = project.multi_show? ? "Plan Crew" : "Staffing Board"
  def primary_staffing_path
    return usr_project_path(project, view: "crew") if project.multi_show?
    usr_company_staffing_path(project.company, project_id: project.id, from: project.starts_on || Date.current)
  end
  def show_overview? = !project.multi_show? || project.description.present?

  def job_status_class(job)
    job.published? ? "status-badge status-open" : "status-badge status-draft"
  end
end
