# frozen_string_literal: true

class Usr::Dashboard::CompanyToolsComponent < ApplicationComponent
  extend Dry::Initializer

  Tool = Data.define(:label, :path, :icon, :primary)

  option :post_job_path, default: proc { "/usr/jobs/select_company" }
  option :staff_gig_path
  option :create_project_path
  option :job_postings_path
  option :projects_path
  option :companies_path

  def tools
    [
      Tool.new(label: "Staff a Gig", path: staff_gig_path, icon: "people", primary: true),
      Tool.new(label: "Post a Job", path: post_job_path, icon: "plus-square", primary: false),
      Tool.new(label: "Staff a Tour / Festival", path: create_project_path, icon: "map", primary: false),
      Tool.new(label: "Job Postings", path: job_postings_path, icon: "card-checklist", primary: false),
      Tool.new(label: "Projects", path: projects_path, icon: "folder2-open", primary: false),
      Tool.new(label: "Companies", path: companies_path, icon: "buildings", primary: false)
    ]
  end
end
