# frozen_string_literal: true

class Usr::Company::ProjectFormComponent < ApplicationComponent
  extend Dry::Initializer

  option :company
  option :project

  def form_url
    project.persisted? ? usr_project_path(project) : usr_company_projects_path(company)
  end
end
