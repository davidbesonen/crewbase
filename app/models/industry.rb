class Industry < ApplicationRecord
  # 11/19/2025: NOT CREATED YET
  has_many :industry_assignments, dependent: :destroy
  has_many :companies, -> { distinct }, through: :industry_assignments, source: :assignable, source_type: "Company"
  has_many :equipment, -> { distinct }, through: :industry_assignments, source: :assignable, source_type: "Equipment"
  has_many :occupations, -> { distinct }, through: :industry_assignments, source: :assignable, source_type: "Occupation"
  has_many :skills, -> { distinct }, through: :industry_assignments, source: :assignable, source_type: "Skill"

  class << self
    def ransackable_attributes(auth_object = nil)
      %w[id name]
    end

    def ransackable_associations(auth_object = nil)
      %w[companies equipment industry_assignments occupations skills]
    end
  end
end
