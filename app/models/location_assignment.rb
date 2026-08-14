class LocationAssignment < ApplicationRecord
  belongs_to :location
  belongs_to :locationable, polymorphic: true
end
