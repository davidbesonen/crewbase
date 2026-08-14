class JobApplication < ApplicationRecord
  REVIEW_STATUSES = %w[in_review shortlisted accepted rejected].freeze
  DECISION_STATUSES = %w[accepted rejected].freeze

  belongs_to :job
  belongs_to :profile
  has_one :conversation, as: :context, dependent: :destroy

  has_one_attached :resume
  has_one_attached :cover_letter_file
  has_many_attached :attachments
  has_rich_text :additional_information

  attribute :question_answers, default: -> { {} }

  validates :job, :profile, :status, presence: true
  validates :profile_id, uniqueness: { scope: :job_id }

  enum :status, {
    submitted: 0,
    in_review: 1,
    shortlisted: 2,
    rejected: 3,
    withdrawn: 4,
    accepted: 5
  }

  validates :status, inclusion: { in: statuses.keys }

  before_validation :set_submitted_at, on: :create

  class << self
    def review_pipeline_statuses
      [ "submitted", *REVIEW_STATUSES ]
    end

    def review_statuses
      REVIEW_STATUSES
    end

    def decision_statuses
      DECISION_STATUSES
    end
  end

  def question_answers=(value)
    normalized_answers = value.to_h.transform_values { |answer| answer.to_s.strip }.compact_blank
    super(normalized_answers)
  end

  def reviewable_by?(user)
    return false if user.blank?

    job.company&.is_owner?(user)
  end

  private

  def set_submitted_at
    self.submitted_at ||= Time.current
  end
end
