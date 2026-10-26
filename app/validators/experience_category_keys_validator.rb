class ExperienceCategoryKeysValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    allowed = ExperienceCategories.all(options.fetch(:type)).map(&:key)
    record.errors.add(attribute, "contain an unknown category") if (Array(value) - allowed).any?
  end
end
