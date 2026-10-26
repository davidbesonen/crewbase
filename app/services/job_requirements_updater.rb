class JobRequirementsUpdater
  SELECTIONS = {
    required_occupation_ids: [ Occupation, :required ],
    required_skill_ids: [ Skill, :required ],
    preferred_skill_ids: [ Skill, :preferred ],
    required_equipment_ids: [ Equipment, :required ],
    preferred_equipment_ids: [ Equipment, :preferred ]
  }.freeze

  def initialize(job:, selections:)
    @job = job
    @selections = selections
  end

  def call
    desired_requirements = build_desired_requirements

    job.transaction do
      SELECTIONS.each do |parameter, (model, importance)|
        next unless selections.key?(parameter)

        job.job_requirements.where(requirement_type: model.name, importance: importance)
          .where.not(id: desired_requirements.filter_map(&:id)).destroy_all
        field = JobExperienceRequirements::TEXT_FIELDS.key([ model.name, importance.to_s ])
        if field
          names = desired_requirements.select { |entry| entry.requirement_type == model.name && entry.importance == importance.to_s }.map { |entry| entry.requirement.name }
          job[field] = ExperienceTerms.new(names).values.join("\n")
        end
      end
      desired_requirements.each(&:save!)
      job.save! if job.changed?
    end
    true
  end

  private

  attr_reader :job, :selections

  def build_desired_requirements
    SELECTIONS.flat_map do |parameter, (model, importance)|
      next [] unless selections.key?(parameter)
      ids = Array(selections[parameter]).compact_blank.map(&:to_i).uniq
      model.where(id: ids).map do |requirement|
        job.job_requirements.find_or_initialize_by(requirement:, importance:).tap do |record|
          record.source = :employer
          record.confirmed_at ||= Time.current
        end
      end
    end
  end
end
