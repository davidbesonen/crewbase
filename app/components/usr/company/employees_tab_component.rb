# frozen_string_literal: true

class Usr::Company::EmployeesTabComponent < ApplicationComponent
  extend Dry::Initializer

  option :company
  option :assignments

  def role_label(assignment)
    assignment.role == "member" ? "Employee" : assignment.role.titleize
  end
end
