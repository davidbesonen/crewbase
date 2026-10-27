class CrewImport < ApplicationRecord
  belongs_to :company
  belongs_to :uploaded_by, class_name: "User"

  def expired? = imported_at.nil? && created_at < 24.hours.ago
end
