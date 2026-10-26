class Admin::ManagedRecordsController < Admin::BaseController
  def show
    prepare_record
    render "admin/records/show"
  end

  def update
    prepare_record
    Admin::ManageRecord.new(actor: current_user, record: @record, attributes: management_params).call
    redirect_to polymorphic_path([ :admin, @record ]), notice: "Change saved and recorded in the audit log."
  rescue Admin::ManageRecord::InvalidAction, ActiveRecord::RecordInvalid => error
    @management_error = error.message
    @submitted = management_params
    render "admin/records/show", status: :unprocessable_entity
  end

  private

  def prepare_record
    @record = record_class.find(params[:id])
    @details = Admin::RecordDetails.new(record: @record).results
    @events = AdminAuditEvent.where(subject: @record).includes(:actor).order(created_at: :desc, id: :desc).limit(20)
    @role_actions = @record.is_a?(User) && current_user.has_role?("app_owner") && @record != current_user && !@record.has_role?("app_owner")
    @restriction_actions = !@record.is_a?(User) || (@record != current_user && !@record.site_admin?)
  end

  def management_params
    params.require(:management).permit(:action, :reason, *Admin::ManageRecord::FIELDS.fetch(record_class.name))
  end
end
