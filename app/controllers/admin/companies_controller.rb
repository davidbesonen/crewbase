class Admin::CompaniesController < Admin::BaseController
  def index
    @pagy, @companies = pagy(Admin::CompaniesQuery.new(params:).results)
  end
end
