class Admin::ProductMetricsController < Admin::BaseController
  def show
    @metrics = Admin::ProductMetrics.new.results
  end
end
