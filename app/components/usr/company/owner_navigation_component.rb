# frozen_string_literal: true

class Usr::Company::OwnerNavigationComponent < ApplicationComponent
  Destination = Data.define(:key, :label, :path, :icon, :secondary, :disabled)
  def initialize(company:, active:, entitlement:)
    @company = company
    @active = active.to_sym
    @entitlement = entitlement
  end

  private

  attr_reader :company, :active, :entitlement

  def feature_available?(feature)
    entitlement.allowed?(feature)
  end

  def button_class(destination, secondary: false)
    return "btn btn-sm btn-quiet" if active == destination

    "btn btn-sm #{secondary ? 'btn-outline-secondary' : 'btn-outline-primary'}"
  end

  def current_destination(destination)
    "page" if active == destination
  end

  def destinations
    @destinations ||= [
      [ :profile, "Profile", usr_company_path(company), "card-heading", false, false ],
      [ :manager, "Manager", usr_company_manager_path(company), "speedometer2", false, !feature_available?(:staffing_analytics) ],
      [ :post_job, "Post a Job", new_usr_company_job_placement_path(company), "plus-square", false, false ],
      [ :projects, "Manage Projects", usr_company_projects_path(company), "folder2-open", false, false ],
      [ :roster, "Crew Roster", usr_company_crew_members_path(company), "people", false, false ],
      [ :staffing, "Staffing Board", usr_company_staffing_path(company), "calendar3", false, false ],
      [ :templates, "Templates", usr_company_gig_templates_path(company), "copy", false, false ],
      [ :venues, "Venues", usr_company_venues_path(company), "geo-alt", false, false ],
      [ :edit, "Edit Company", edit_usr_company_path(company), "pencil", true, false ],
      [ :plan, entitlement.tier == "studio" ? "Manage Plan" : "Upgrade Plan", usr_company_plan_path(company), "arrow-up-circle", true, false ]
    ].map { |key, label, path, icon, secondary, disabled| Destination.new(key:, label:, path:, icon:, secondary:, disabled:) }
  end

  def mobile_options = destinations.map { |item| [ item.label, item.path, { disabled: item.disabled, selected: item.key == active } ] }
end
