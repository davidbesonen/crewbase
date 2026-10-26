class ExperienceTermsValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    terms = ExperienceTerms.new(value).values
    record.errors.add(attribute, "must contain at most #{ExperienceTerms::MAX_ENTRIES} entries") if terms.size > ExperienceTerms::MAX_ENTRIES
    record.errors.add(attribute, "entries must be #{ExperienceTerms::MAX_ENTRY_LENGTH} characters or fewer") if terms.any? { |term| term.length > ExperienceTerms::MAX_ENTRY_LENGTH }
    record.errors.add(attribute, "is too long") if value.to_s.length > ExperienceTerms::MAX_TEXT_LENGTH
  end
end
