# frozen_string_literal: true

class Usr::Dashboard::CompanyToolsComponent < ApplicationComponent
  extend Dry::Initializer

  Tool = Data.define(:label, :path, :icon, :primary)

  option :post_job_path
  option :create_project_path
  option :job_postings_path
  option :projects_path
  option :companies_path

  def tools
    [
      Tool.new(label: "Post a Job", path: post_job_path, icon: "briefcase", primary: true),
      Tool.new(label: "Create a Project", path: create_project_path, icon: "kanban", primary: false),
      Tool.new(label: "Job Postings", path: job_postings_path, icon: "card-checklist", primary: false),
      Tool.new(label: "Projects", path: projects_path, icon: "folder2-open", primary: false),
      Tool.new(label: "Companies", path: companies_path, icon: "buildings", primary: false)
    ]
  end
end
