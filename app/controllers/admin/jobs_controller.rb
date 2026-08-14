class Admin::JobsController < Admin::BaseController
  def index
    @pagy, @jobs = pagy(Admin::JobsQuery.new(params:).results)
  end
end
