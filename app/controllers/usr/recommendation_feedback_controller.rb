class Usr::RecommendationFeedbackController < ApplicationController
  def index
    @feedback = RecommendationFeedback.where(user: current_user).includes(job: :company).order(updated_at: :desc)
  end

  def create
    job = Job.accepting_applications.find(params[:job_id])
    feedback = RecommendationFeedback.find_or_initialize_by(user: current_user, job:)
    feedback.reason = params[:reason].presence || "not_relevant"
    if feedback.save
      ProductEvent.record(user: current_user, name: "recommendation_dismissed", subject: job, event_key: job.id)
      redirect_to usr_dashboards_path, notice: "Recommendation hidden. You can restore it from Hidden recommendations."
    else
      redirect_to usr_dashboards_path, alert: feedback.errors.full_messages.to_sentence
    end
  end

  def destroy
    RecommendationFeedback.where(user: current_user, job_id: params[:job_id]).destroy_all
    redirect_to usr_recommendation_feedback_index_path, notice: "Recommendation restored if it still matches your profile."
  end
end
