class Admin::CompaniesController < Admin::ManagedRecordsController
  def index
    @pagy, @companies = pagy(Admin::CompaniesQuery.new(params:).results)
  end
  private

  def record_class
    Company
  end
end
