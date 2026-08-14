class EquipmentAssignment < ApplicationRecord
  belongs_to :equipment
  belongs_to :profile
end
