# Retire the previous markets from discovery without deleting anyone's history.
# Unclassified legacy records remain accessible; new companies are always touring.
class TouringMarketplace
  def self.companies(scope)
    assignments = IndustryAssignment.where(assignable_type: "Company")
    retired = assignments.where(industry_id: Industry.where(name: TouringCatalog.retired_industries)).select(:assignable_id)
    touring = assignments.where(industry_id: Industry.where(name: TouringCatalog.industry_name)).select(:assignable_id)
    scope.where.not(id: retired).or(scope.where(id: touring))
  end

  def self.profiles(scope)
    assignments = OccupationAssignment.where(assignable_type: "Profile")
    touring = assignments.where(occupation_id: Occupation.touring).select(:assignable_id)
    retired = assignments.where(occupation_id: Occupation.retired).select(:assignable_id)
    scope.where.not(id: retired).or(scope.where(id: touring))
  end

  def self.jobs(scope)
    scope = scope.where(company_id: companies(Company.all).select(:id))
    requirements = JobRequirement.where(requirement_type: "Occupation")
    retired = requirements.where(requirement_id: Occupation.retired).select(:job_id)
    touring = requirements.where(requirement_id: Occupation.touring).select(:job_id)
    scope.where.not(id: retired).or(scope.where(id: touring))
  end
end
