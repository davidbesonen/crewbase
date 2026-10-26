class Admin::JobsController < Admin::ManagedRecordsController
  def index
    @pagy, @jobs = pagy(Admin::JobsQuery.new(params:).results)
  end
  private

  def record_class
    Job
  end
end
