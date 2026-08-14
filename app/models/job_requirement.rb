class JobRequirement < ApplicationRecord
  REQUIREMENT_TYPES = %w[Occupation Skill Equipment].freeze

  belongs_to :job
  belongs_to :requirement, polymorphic: true

  enum :importance, {
    required: 0,
    preferred: 1
  }, validate: true

  enum :source, {
    employer: 0,
    ai_suggested: 1
  }, validate: true

  validates :requirement_type, inclusion: { in: REQUIREMENT_TYPES }
  validates :requirement_id,
    uniqueness: { scope: [ :job_id, :requirement_type, :importance ] }
end
