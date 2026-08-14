class CrewPosition < ApplicationRecord
  include Compensated

  belongs_to :job

  has_many :crew_assignments, dependent: :destroy
  has_many :profiles, through: :crew_assignments

  validates :title, presence: true
  validates :headcount, numericality: { only_integer: true, greater_than: 0 }
  validate :job_must_be_multi_position

  private

  def job_must_be_multi_position
    return if job&.multi_position?

    errors.add(:job, "must be a multi-position gig")
  end
end
