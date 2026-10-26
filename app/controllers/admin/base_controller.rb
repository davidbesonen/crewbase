class Admin::BaseController < ApplicationController
  before_action :require_admin

  private

  def require_admin
    return if current_user.site_admin?

    redirect_to usr_dashboards_path, alert: "You are not authorized to access that page."
  end
end
