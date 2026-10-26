class Admin::UsersController < Admin::ManagedRecordsController
  def index
    @pagy, @users = pagy(Admin::UsersQuery.new(params:).results)
  end
  private

  def record_class
    User
  end
end
