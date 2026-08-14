class Conversation < ApplicationRecord
  CONTEXT_TYPES = %w[JobApplication JobInvitation].freeze

  belongs_to :context, polymorphic: true
  has_many :memberships, class_name: "ConversationMembership", dependent: :destroy
  has_many :users, through: :memberships
  has_many :messages, -> { order(:created_at, :id) }, class_name: "ContextualMessage", dependent: :destroy

  validates :context_type, inclusion: { in: CONTEXT_TYPES }
  validates :context_id, uniqueness: { scope: :context_type }

  def title
    context.job.title
  end

  def context_label
    context_type == "JobApplication" ? "Job application" : "Job invitation"
  end
end
