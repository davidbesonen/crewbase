class Usr::OnboardingController < ApplicationController
  def show
    @quick_start = CompleteQuickStart.new(user: current_user, intent: current_user.onboarding_intent, occupation_ids: current_user.user_profile&.occupation_ids)
    @occupations = OccupationCatalog.new.records
    ProductEvent.record(user: current_user, name: "onboarding_started", event_key: "once")
  end

  def update
    @quick_start = CompleteQuickStart.new(onboarding_params.merge(user: current_user))
    if @quick_start.call
      destination = @quick_start.intent == "hire_crew" && current_user.owned_companies.empty? ? new_usr_company_path : usr_dashboards_path
      redirect_to destination, notice: "You're ready to explore. Add more profile details whenever you like."
    else
      @occupations = OccupationCatalog.new.records
      render :show, status: :unprocessable_content
    end
  end

  private

  def onboarding_params
    params.require(:onboarding).permit(:intent, occupation_ids: [])
  end
end
