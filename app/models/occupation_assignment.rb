class OccupationAssignment < ApplicationRecord
  belongs_to :occupation
  belongs_to :assignable, polymorphic: true

  validates :occupation_id, uniqueness: { scope: [ :assignable_type, :assignable_id ] }
end
