class JobShow < ApplicationRecord
  belongs_to :job
  belongs_to :project_show
  validates :project_show_id, uniqueness: { scope: :job_id }
  validate do
    errors.add(:project_show, "must belong to the posting's project") unless project_show&.project_id == job&.project_id
  end
end
