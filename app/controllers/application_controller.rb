class ApplicationController < ActionController::Base
  include RansackMemory::Concern
  include Pagy::Backend

  before_action :authenticate_user!
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  unless Rails.env.development?
    # Only enforce modern browser requirements outside of development
    allow_browser versions: :modern
  end

  before_action :set_page_title
  before_action :configure_permitted_parameters, if: :devise_controller?

  def set_page_title
    @page_title = controller_name.titleize
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name ])
  end

  def after_sign_in_path_for(resource)
    if resource.has_role?("admin")
      admin_users_path
    else
      usr_dashboards_path
    end
  end
end
