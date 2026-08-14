class ApplicationComponent < ViewComponent::Base
  extend Dry::Initializer
  delegate :current_user, to: :helpers
  delegate :rich_text_area, to: :helpers
  delegate :rich_textarea_tag, to: :helpers
  delegate :turbo_frame_tag, to: :helpers
  delegate :job_application_status_badge_class, to: :helpers
  delegate :project_status_badge_class, to: :helpers

  def fix_dt(dt)
    dt&.strftime("%m/%d/%Y %I:%M %p")
  end

  def recommendation_rating_text_class(rating)
    if rating >= 4.0
      "text-success"
    elsif rating >= 3.0
      "text-warning"
    else
      "text-danger"
    end
  end
end
