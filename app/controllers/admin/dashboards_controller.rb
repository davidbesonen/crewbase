class Admin::DashboardsController < Admin::BaseController
  def show
    @dashboard = Admin::DashboardQuery.new(date_range: 29.days.ago.to_date..Time.current.to_date).call
  end
end
