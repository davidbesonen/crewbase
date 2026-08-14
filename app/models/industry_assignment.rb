class IndustryAssignment < ApplicationRecord
  belongs_to :industry
  belongs_to :assignable, polymorphic: true

  validates :industry_id, uniqueness: { scope: [ :assignable_type, :assignable_id ] }
end
