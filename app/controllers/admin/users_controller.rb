class Admin::UsersController < Admin::BaseController
  def index
    @pagy, @users = pagy(Admin::UsersQuery.new(params:).results)
  end
end
