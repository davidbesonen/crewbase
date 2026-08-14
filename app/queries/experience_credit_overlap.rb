class ExperienceCreditOverlap
  def initialize(experience:, credits:)
    @experience = experience
    @credits = credits
  end

  def results
    return [] if experience.start_year.blank? && experience.end_year.blank?

    credits.select { |credit| same_company?(credit) && overlapping_year?(credit) }
  end

  private

  attr_reader :experience, :credits

  def same_company?(credit)
    return credit.company_id == experience.company_id if credit.company_id.present? && experience.company_id.present?

    credit.display_company.to_s.casecmp?(experience.company_name.to_s)
  end

  def overlapping_year?(credit)
    return false if credit.starts_on.blank?

    start_year = experience.start_year.presence&.to_i || experience.end_year.to_i
    end_year = experience.currently_active? ? Date.current.year : (experience.end_year.presence&.to_i || start_year)
    (start_year..end_year).cover?(credit.starts_on.year)
  end
end
