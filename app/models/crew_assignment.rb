class CrewAssignment < ApplicationRecord
  belongs_to :crew_position
  belongs_to :profile

  validates :profile_id, uniqueness: { scope: :crew_position_id }
  validate :position_must_have_room, on: :create

  private

  def position_must_have_room
    return if crew_position.blank?
    other_assignments = crew_position.crew_assignments.where.not(id:).count
    return if other_assignments < crew_position.headcount

    errors.add(:crew_position, "is already fully staffed")
  end
end
