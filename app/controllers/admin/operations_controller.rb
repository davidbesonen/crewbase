class Admin::OperationsController < Admin::BaseController
  def show
    @operations = Admin::OperationalReadiness.new.call
  end
end
