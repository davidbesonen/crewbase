class CrewShortlist < ApplicationRecord
  belongs_to :company
  belongs_to :created_by, class_name: "User"

  has_many :crew_shortlist_memberships, dependent: :destroy
  has_many :profiles, through: :crew_shortlist_memberships

  validates :name, presence: true, uniqueness: { scope: :company_id }
end
