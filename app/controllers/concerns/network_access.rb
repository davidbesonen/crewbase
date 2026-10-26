module NetworkAccess
  extend ActiveSupport::Concern

  included do
    before_action :require_network_profile
  end

  private

  def require_network_profile
    return if current_user.profiles.network_visible.exists?

    redirect_to usr_dashboards_path, alert: "Complete your crew profile to use your network."
  end
end
