class CrewHold < ApplicationRecord
  belongs_to :job
  belongs_to :crew_position, optional: true
  belongs_to :crew_member
  before_validation do
    self.job ||= crew_position&.job
  end
  validates :crew_member_id, uniqueness: { scope: [ :job_id, :crew_position_id ] }
  validate :same_company

  private

  def same_company
    errors.add(:crew_member, "must belong to this company") unless crew_member&.company_id == job&.company_id
    errors.add(:crew_position, "must belong to this gig") if crew_position && crew_position.job_id != job_id
    errors.add(:crew_position, "is required for a multi-position gig") if job&.multi_position? && !crew_position
  end
end
