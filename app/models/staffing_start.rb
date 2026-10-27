class StaffingStart
  include ActiveModel::Model

  KINDS = %w[single multi_show].freeze
  attr_accessor :company_id, :kind
  validates :company_id, presence: { message: "Choose a company." }
  validates :kind, inclusion: { in: KINDS, message: "Choose a single gig or a multi-show event." }
end
