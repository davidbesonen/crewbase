# frozen_string_literal: true

class Usr::Company::OwnerNavigationComponent < ApplicationComponent
  Destination = Data.define(:key, :label, :path, :icon)
  SECONDARY_LABELS = {
    profile: "Company Profile", templates: "Templates", venues: "Venues",
    edit: "Edit Company", plan: "Plan & Billing"
  }.freeze

  def initialize(company:, active:, entitlement:)
    @company = company
    @active = active.to_sym
  end

  private

  attr_reader :company, :active

  def button_class(destination)
    active == destination ? "btn btn-sm btn-quiet" : "btn btn-sm btn-outline-primary"
  end

  def current_destination(destination)
    "page" if active == destination
  end

  def destinations
    @destinations ||= [
      [ :manager, "Manager", usr_company_manager_path(company), "speedometer2" ],
      [ :projects, "Projects", usr_company_projects_path(company), "folder2-open" ],
      [ :roster, "Crew Roster", usr_company_crew_members_path(company), "people" ],
      [ :staffing, "Staffing Board", usr_company_staffing_path(company), "calendar3" ],
      [ :post_job, "Post a Job", new_usr_company_job_placement_path(company), "plus-square" ]
    ].map { |key, label, path, icon| Destination.new(key:, label:, path:, icon:) }
  end

  def mobile_options
    options = destinations.map { |item| [ item.label, item.path, { selected: item.key == active } ] }
    return options if destinations.any? { |item| item.key == active }

    [ [ SECONDARY_LABELS.fetch(active, "Company Workspace"), "", { disabled: true, selected: true } ], *options ]
  end
end
