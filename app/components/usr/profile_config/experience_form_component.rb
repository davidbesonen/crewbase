# frozen_string_literal: true

class Usr::ProfileConfig::ExperienceFormComponent < ApplicationComponent
  extend Dry::Initializer

  option :f
  option :add_experience, default: proc { false }
  option :credits, default: proc { [] }

  def month_options
    Date::MONTHNAMES.compact
  end

  def year_options
    current_year = Date.current.year
    current_year.downto(current_year - 50).map(&:to_s)
  end

  def editable_experiences
    records = f.object.experiences.display_order.to_a
    records << Experience.new if add_experience
    records
  end

  def company_icon_url(experience)
    experience.company&.image_url
  end

  def company_initial(experience)
    experience.company&.name&.first&.upcase || "C"
  end

  def overlapping_credits(experience)
    ExperienceCreditOverlap.new(experience:, credits:).results
  end
end
