class JobExperienceRequirements
  Entry = Data.define(:type, :name, :importance, :record, :category_key) do
    def required? = importance == "required"
  end
  TEXT_FIELDS = {
    required_skills_text: [ "Skill", "required" ],
    preferred_skills_text: [ "Skill", "preferred" ],
    required_equipment_text: [ "Equipment", "required" ],
    preferred_equipment_text: [ "Equipment", "preferred" ]
  }.freeze

  def initialize(job)
    @job = job
  end

  def entries
    occupation_entries + category_entries + TEXT_FIELDS.flat_map do |field, (type, importance)|
      names_for(field).map { |name| Entry.new(type:, name:, importance:, record: nil, category_key: nil) }
    end
  end

  def names_for(field)
    type, importance = TEXT_FIELDS.fetch(field)
    value = @job.public_send(field)
    value = legacy.select { |entry| entry.requirement_type == type && entry.importance == importance }.map { |entry| entry.requirement.name } if value.nil?
    terms = type == "Equipment" ? EquipmentTerms : ExperienceTerms
    terms.new(value).values
  end

  private

  def category_entries
    ExperienceCategories::JOB_FIELDS.flat_map do |field, (type, importance)|
      ExperienceCategories.selected(type, @job.public_send(field)).map do |category|
        Entry.new(type:, name: category.name, importance:, record: nil, category_key: category.key)
      end
    end
  end

  def legacy
    @legacy ||= @job.job_requirements.to_a
  end

  def occupation_entries
    legacy.select { |entry| entry.requirement_type == "Occupation" }.map do |entry|
      Entry.new(type: "Occupation", name: entry.requirement.name, importance: entry.importance, record: entry.requirement, category_key: nil)
    end
  end
end
