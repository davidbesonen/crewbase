class GigTemplate < ApplicationRecord
  belongs_to :company
  validates :name, presence: true, length: { maximum: 150 }, uniqueness: { scope: :company_id }

  def self.capture!(job:, name:, user:)
    raise ActiveRecord::RecordNotFound unless job.company.is_owner?(user)

    job.company.gig_templates.create!(name:, setup: GigSetup.new(job:).to_h)
  end
end
