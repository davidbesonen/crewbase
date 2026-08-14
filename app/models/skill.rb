class Skill < ApplicationRecord
  has_many :skill_assignments, dependent: :destroy
  has_many :profiles, through: :skill_assignments
  has_many :occupation_assignments, as: :assignable, dependent: :destroy
  has_many :occupations, -> { distinct }, through: :occupation_assignments
  has_many :industry_assignments, as: :assignable, dependent: :destroy
  has_many :industries, -> { distinct }, through: :industry_assignments

  class << self
    def ransackable_attributes(auth_object = nil)
      %w[id name]
    end

    def ransackable_associations(auth_object = nil)
      %w[industry_assignments industries occupation_assignments occupations profiles]
    end
  end

  def industry_names
    industries.order(:name).pluck(:name)
  end

  def industry_names_text
    industry_names.to_sentence
  end

  def occupation_names
    occupations.order(:name).pluck(:name)
  end

  def occupation_names_text
    occupation_names.to_sentence
  end
end
