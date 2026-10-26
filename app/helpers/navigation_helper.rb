module NavigationHelper
  def user_sidenav_link_options(section, company: nil)
    active = user_navigation_section == section
    active &&= company.id.to_s == user_navigation_company_id if company

    navigation_link_options(active, "nav-link d-flex align-items-center text-dark")
  end

  private

  def navigation_link_options(active, classes)
    { class: class_names(classes, active: active), aria: { current: active ? "page" : nil } }
  end

  def user_navigation_section
    @user_navigation_section ||= case controller_name
    when "dashboards" then :dashboard
    when "networks", "network_connections", "network_job_shares" then :network
    when "settings", "billing" then :settings
    when "profiles", "credits", "calendar_events"
      profile_id = params[:profile_id] || params[:id]
      profile_id.to_s == current_profile&.id.to_s ? :my_profile : :people
    when "jobs", "saved_jobs", "job_applications", "job_crews", "crew_positions", "crew_assignments", "job_contracts", "applications"
      :jobs
    when "projects" then :projects
    when "notifications" then :notifications
    when "conversations", "contextual_messages" then :messages
    when "job_invitations" then :invitations
    when "job_offers" then :offers
    when "companies"
      if action_name.in?(%w[new create next_form previous_form])
        :create_company
      else
        user_navigation_company_section
      end
    when "company_managers", "company_plans", "company_billing_checkouts", "company_billing_portals", "crew_shortlists", "crew_shortlist_memberships"
      user_navigation_company_section
    when "reviews"
      params[:profile_id].present? ? :people : user_navigation_company_section
    end
  end

  def user_navigation_company_section
    @sidenav_companies&.any? { |company| company.id.to_s == user_navigation_company_id } ? :company : :companies
  end

  def user_navigation_company_id
    (params[:company_id] || (params[:id] if controller_name == "companies")).to_s
  end
end
