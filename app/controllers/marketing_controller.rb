class MarketingController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    return redirect_to usr_dashboards_path if current_user

    @marketing_page = true
    @page_title = "Crewbase | Live event teams, connected"
    @meta_description = "Crewbase helps live event professionals find work, build trusted crews, and manage staffing from first search through show day."
    @primary_cta_label = "Join Crewbase"
    @primary_cta_path = new_user_registration_path
  end

  def team
    @marketing_page = true
    @page_title = "Meet the Team | Crewbase"
    @meta_description = "Meet Crewbase co-founders David Besonen and Dayne deHaven and learn why they are building a better way to staff live entertainment."
    @primary_cta_label = current_user ? "Open Crewbase" : "Join Crewbase"
    @primary_cta_path = current_user ? usr_dashboards_path : new_user_registration_path
  end
end
