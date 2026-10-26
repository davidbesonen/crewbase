class Usr::ReportsController < ApplicationController
  def index
    @reports = SafetyReport.where(reporter: current_user).order(created_at: :desc)
    @blocks = UserBlock.where(blocker: current_user).includes(blocked_user: :profiles).order(created_at: :desc)
    @received_reviews = Review.where(reviewable: current_user.profiles)
      .or(Review.where(reviewable: current_user.owned_companies))
      .includes(profile: :user).order(created_at: :desc)
  end

  def new
    @subject = ReportableSubject.new(user: current_user, type: params[:subject_type], id: params[:subject_id]).call
    @report = SafetyReport.new(subject: @subject, category: params[:category])
  end

  def create
    permitted = params.require(:report).permit(:subject_type, :subject_id, :category, :details)
    @subject = ReportableSubject.new(user: current_user, type: permitted[:subject_type], id: permitted[:subject_id]).call
    @report = SafetyReport.new(permitted.except(:subject_type, :subject_id))
    @report.assign_attributes(subject: @subject, reporter: current_user, subject_label: subject_label)
    if @report.save
      redirect_to usr_reports_path, notice: "Report received. You can follow its status here."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def subject_label
    case @subject
    when Job then @subject.title
    when Company then @subject.name
    when Profile then @subject.user.full_name
    when Credit then "#{@subject.role} — #{@subject.project_name}"
    when Review then "Review by #{@subject.profile.user.full_name}"
    when Conversation then "Conversation: #{@subject.title}"
    end
  end
end
