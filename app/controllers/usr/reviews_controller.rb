class Usr::ReviewsController < ApplicationController
  before_action :set_reviewable, only: [ :new, :create ]
  before_action :set_authored_review, only: [ :edit, :update, :destroy ]

  def new
    @review = Review.new(reviewable: @reviewable)
    set_rating_fields

    render layout: false if turbo_frame_request?
  end

  def create
    @review = Review.new(review_params)
    @review.reviewable = @reviewable
    @review.profile = current_user.user_profile
    @review.overall_rating = (review_params[:rating_data].values.map(&:to_i).sum / review_params[:rating_data].values.size.to_f).round(1)

    if @review.save
      redirect_to reviewable_path, notice: "Review submitted!"
    else
      set_rating_fields
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    set_rating_fields
    render layout: false if turbo_frame_request?
  end

  def update
    @review.overall_rating = (review_params[:rating_data].values.map(&:to_i).sum / review_params[:rating_data].values.size.to_f).round(1)

    if @review.update(review_params)
      redirect_to reviewable_path, notice: "Review updated!"
    else
      set_rating_fields
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @review.destroy
    redirect_to reviewable_path, notice: "Review deleted!"
  end

  private

  def set_reviewable
    @reviewable =
      if params[:company_id].present?
        Company.find(params[:company_id])
      elsif params[:profile_id].present?
        Profile.find(params[:profile_id])
      end
  end

  def set_authored_review
    @review = current_user.user_profile.authored_reviews.find(params[:id])
    @reviewable = @review.reviewable
  end

  def set_rating_fields
    @company_rating_fields = [
      [ "Communication/Clarity", "communication_clarity" ],
      [ "Payment Timeliness", "payment_timeliness" ],
      [ "Working Conditions/Safety", "working_conditions_safety" ],
      [ "Professionalism/Respect", "professionalism_respect" ],
      [ "Accuracy of Call/Scope (was the gig described correctly?)", "accuracy_of_call_scope" ]
    ]

    @worker_rating_fields = [
      [ "Reliability (on time/prepared)", "reliability" ],
      [ "Skill/Quality of Work", "skill_quality" ],
      [ "Communication", "communication" ],
      [ "Professionalism/Attitude", "professionalism_attitude" ],
      [ "Team Fit (optional—this one can be subjective, so consider omitting)", "team_fit" ]
    ]
  end

  def review_params
    params.require(:review).permit(:body, :overall_rating, rating_data: {})
  end

  def reviewable_path
    @reviewable.is_a?(Company) ? usr_company_path(@reviewable) : usr_profile_path(@reviewable)
  end
end
