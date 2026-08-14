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

    job.job_requirements.where.not(id: desired_requirements.filter_map(&:id)).destroy_all
    desired_requirements.each(&:save!)
    true
  end

  private

  attr_reader :job, :selections

  def build_desired_requirements
    SELECTIONS.flat_map do |parameter, (model, importance)|
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
