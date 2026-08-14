class Admin::UsersQuery
  def initialize(params:)
    @params = params
  end

  def results
    scope = User.includes(:roles, :profiles, :companies).order(created_at: :desc, id: :desc)
    params[:q].present? ? scope.where("users.email ILIKE :q OR users.first_name ILIKE :q OR users.last_name ILIKE :q", q: "%#{User.sanitize_sql_like(params[:q])}%") : scope
  end

  private

  attr_reader :params
end
