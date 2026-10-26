class Admin::ReportsController < Admin::BaseController
  def index
    @status = SafetyReport.statuses.key?(params[:status]) ? params[:status] : "open"
    @pagy, @reports = pagy(SafetyReport.where(status: @status).includes(:reporter).order(created_at: :asc, id: :asc))
    @counts = SafetyReport.group(:status).count
  end

  def show
    prepare_report
    @decision = ModerationDecision.new
  end

  def update
    prepare_report
    attributes = params.require(:moderation_decision).permit(:status, :notes)
    ModerateSafetyReport.new(report: @report, moderator: current_user, status: attributes[:status], notes: attributes[:notes]).call
    redirect_to admin_report_path(@report), notice: "Decision recorded."
  rescue ActiveRecord::RecordInvalid => error
    @decision = error.record
    render :show, status: :unprocessable_entity
  end

  private

  def prepare_report
    @report = SafetyReport.find(params[:id])
    @management_targets = Admin::ReportManagementTargets.new(@report).results
    @decisions = @report.moderation_decisions.includes(:moderator).order(:created_at, :id)
  end
end
