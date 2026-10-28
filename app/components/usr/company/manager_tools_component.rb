class Usr::Company::ManagerToolsComponent < ApplicationComponent
  Tool = Data.define(:title, :description, :path, :icon)

  def initialize(company:, analytics_available:)
    @company = company
    @analytics_available = analytics_available
  end

  private

  attr_reader :company, :analytics_available

  def tools
    [
      Tool.new(title: "Company Profile", description: "View how your company appears to crew.", path: usr_company_path(company), icon: "building"),
      Tool.new(title: "Edit Company", description: "Update company details and contact information.", path: edit_usr_company_path(company), icon: "pencil"),
      Tool.new(title: "Templates", description: "Reuse saved gig setups for your next posting.", path: usr_company_gig_templates_path(company), icon: "copy"),
      Tool.new(title: "Venues", description: "Manage saved venues and production details.", path: usr_company_venues_path(company), icon: "geo-alt"),
      Tool.new(title: "Plan & Billing", description: "Review your plan, limits, and billing options.", path: usr_company_plan_path(company), icon: "credit-card")
    ]
  end
end
