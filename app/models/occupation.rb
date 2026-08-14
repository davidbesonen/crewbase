class Occupation < ApplicationRecord
  has_many :occupation_assignments, dependent: :destroy
  has_many :profile_occupation_assignments, -> { where(assignable_type: "Profile") }, class_name: "OccupationAssignment"
  has_many :profiles, through: :profile_occupation_assignments, source: :assignable, source_type: "Profile"
  has_many :skill_occupation_assignments, -> { where(assignable_type: "Skill") }, class_name: "OccupationAssignment"
  has_many :skills, through: :skill_occupation_assignments, source: :assignable, source_type: "Skill"
  has_many :equipment_occupation_assignments, -> { where(assignable_type: "Equipment") }, class_name: "OccupationAssignment"
  has_many :equipment, through: :equipment_occupation_assignments, source: :assignable, source_type: "Equipment"
  has_many :industry_assignments, as: :assignable, dependent: :destroy
  has_many :industries, -> { distinct }, through: :industry_assignments

  class << self
    def ransackable_attributes(auth_object = nil)
      %w[id name]
    end

    def ransackable_associations(auth_object = nil)
      %w[equipment industry_assignments industries occupation_assignments profiles skills]
    end
  end

  def industry_names
    industries.order(:name).pluck(:name)
  end

  def industry_names_text
    industry_names.to_sentence
  end
end
