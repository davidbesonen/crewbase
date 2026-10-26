class MarketingController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    return redirect_to usr_dashboards_path if current_user

    prepare_homepage
  end

  def preview
    prepare_homepage
    render :show
  end

  def brand
    @marketing_page = true
    @page_title = "KnowShow | Logo directions"
  end

  def team
    @marketing_page = true
    @page_title = "Meet the Team | KnowShow"
    @meta_description = "Meet KnowShow co-founders David Besonen and Dayne deHaven and learn why they are building a better way to staff live entertainment."
    @primary_cta_label = current_user ? "Open KnowShow" : "Start staffing"
    @primary_cta_path = current_user ? usr_dashboards_path : new_user_registration_path
  end

  private

  def prepare_homepage
    @marketing_page = true
    @brand_concept = BrandIdentity.concept(params[:concept]).key
    @page_title = "KnowShow | Crew staffing for live music touring"
    @meta_description = BrandIdentity::DESCRIPTION
    @primary_cta_label = current_user ? "Open KnowShow" : "Start staffing"
    @primary_cta_path = current_user ? usr_dashboards_path : new_user_registration_path
  end
end
