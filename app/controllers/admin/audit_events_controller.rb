class Admin::AuditEventsController < Admin::BaseController
  def index
    scope = AdminAuditEvent.includes(:actor).order(created_at: :desc, id: :desc)
    scope = scope.where(subject_type: params[:subject_type]) if %w[User Company Job SafetyReport].include?(params[:subject_type])
    scope = scope.where(subject_id: params[:subject_id]) if params[:subject_id].present?
    if params[:q].present?
      scope = scope.where("reason ILIKE ?", "%#{AdminAuditEvent.sanitize_sql_like(params[:q])}%")
    end
    @pagy, @events = pagy(scope)
  end
end
