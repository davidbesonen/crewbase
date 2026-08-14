class CrewShortlistMembership < ApplicationRecord
  belongs_to :crew_shortlist
  belongs_to :profile

  validates :profile_id, uniqueness: { scope: :crew_shortlist_id }
end
