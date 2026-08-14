# frozen_string_literal: true

class Usr::ProjectDashboardComponent < ApplicationComponent
  extend Dry::Initializer

  option :project
  option :jobs

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
    new_usr_company_job_path(project.company, project_id: project.id)
  end

  def job_status_class(job)
    job.published? ? "status-badge status-open" : "status-badge status-draft"
  end
end
