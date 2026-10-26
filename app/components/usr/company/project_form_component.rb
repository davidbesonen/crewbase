# frozen_string_literal: true

class Usr::Company::ProjectFormComponent < ApplicationComponent
  extend Dry::Initializer

  option :company
  option :project

  def options_expanded?
    project.persisted? || project.description.present? || project.starts_on.present? || project.ends_on.present? || !project.planning? || project.errors.any?
  end

  def form_url
    project.persisted? ? usr_project_path(project) : usr_company_projects_path(company)
  end
end
