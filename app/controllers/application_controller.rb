class ApplicationController < ActionController::Base
  include RansackMemory::Concern
  include Pagy::Backend
  helper Pagy::Frontend

  before_action :authenticate_user!
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  unless Rails.env.development?
    # Only enforce modern browser requirements outside of development
    allow_browser versions: :modern
  end

  before_action :set_page_title
  before_action :set_unread_notification_count
  before_action :set_projects_navigation_path
  before_action :configure_permitted_parameters, if: :devise_controller?

  def set_page_title
    @page_title = "#{current_user ? current_user.full_name : 'Welcome'} | Crewbase"
  end

  def current_profile
    return nil unless current_user

    if session[:current_profile_id].present?
      current_user.profiles.find_by(id: session[:current_profile_id]) || current_user.profiles.first
    else
      current_user.profiles.first
    end
  end
  helper_method :current_profile

  private

  def set_unread_notification_count
    @unread_notification_count = current_user&.notifications&.unread&.count.to_i
  end

  def set_projects_navigation_path
    return unless current_user

    companies = current_user.owned_companies.distinct.order(:name).to_a
    @sidenav_companies = current_user.companies.distinct.order(:name).to_a
    @projects_navigation_path = if companies.one?
      usr_company_projects_path(companies.first)
    elsif companies.many?
      select_company_usr_projects_path
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name ])
  end

  def after_sign_in_path_for(resource)
    return session.delete(:return_to_after_auth) if session[:return_to_after_auth].present?

    if resource.is_a?(User)
      profile = resource.profiles.find_or_create_by(profile_type: "user")
      return edit_usr_profile_path(profile) if needs_profile_setup?(resource)
    end

    if resource.has_role?("admin")
      admin_root_path
    else
      usr_dashboards_path
    end
  end

  def needs_profile_setup?(user)
    return false unless user.is_a?(User)

    !user.visits.exists? || !user.has_completed_user_profile?
  end
end
