class CompanyProjectCapacity
  def initialize(company:)
    @entitlement = CompanyPlanEntitlement.new(company)
  end

  def enforced? = @entitlement.current_plan&.data&.key?("projects_limit")
  def available? = !enforced? || @entitlement.within_limit?(:active_projects)
  def message = "#{@entitlement.current_plan.name} plan allows #{@entitlement.limit(:active_projects)} active projects. Archive or complete a project, or upgrade your plan."
end
