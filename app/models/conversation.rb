class Conversation < ApplicationRecord
  CONTEXT_TYPES = %w[JobApplication JobInvitation].freeze

  belongs_to :context, polymorphic: true
  has_many :memberships, class_name: "ConversationMembership", dependent: :destroy
  has_many :users, through: :memberships
  has_many :messages, -> { order(:created_at, :id) }, class_name: "ContextualMessage", dependent: :destroy

  has_one :latest_message, -> { order(created_at: :desc, id: :desc) }, class_name: "ContextualMessage"

  validates :context_type, inclusion: { in: CONTEXT_TYPES }
  validates :context_id, uniqueness: { scope: :context_type }

  def accessible_to?(user)
    user.present? && !user.restricted_at? && ConversationParticipants.new(context:).users.include?(user)
  end

  def archived?
    context.job.conversation_archived?
  end

  def title
    context.job.title
  end

  def context_label
    context_type == "JobApplication" ? "Job application" : "Job invitation"
  end
end
