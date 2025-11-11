class ApplicationComponent < ViewComponent::Base
  extend Dry::Initializer
  delegate :rich_text_area, to: :helpers
  delegate :turbo_frame_tag, to: :helpers

  def fix_dt(dt)
    dt&.strftime("%m/%d/%Y %I:%M %p")
  end
end
