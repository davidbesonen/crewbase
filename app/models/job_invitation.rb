class JobInvitation < ApplicationRecord
  belongs_to :job
  belongs_to :profile, optional: true
  belongs_to :invited_by, class_name: "User"
  has_one :notification, as: :notifiable, dependent: :destroy
  has_one :conversation, as: :context, dependent: :destroy

  enum :status, {
    pending: 0,
    accepted: 1,
    declined: 2
  }

  scope :received_by, lambda { |user|
    profile_ids = user.profiles.select(:id)
    where(profile_id: profile_ids)
      .or(where("LOWER(job_invitations.email) = ?", user.email.to_s.downcase))
  }

  has_secure_token

  before_validation :normalize_email

  validates :profile_id, uniqueness: { scope: :job_id }, allow_nil: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, if: -> { profile.nil? }
  validates :email, uniqueness: { scope: :job_id, case_sensitive: false }, allow_blank: true
  validate :recipient_must_be_present
  validate :job_must_be_invitable
  validate :inviter_must_own_job_company

  def accept!
    respond!(:accepted)
  end

  def decline!
    respond!(:declined)
  end

  def claim!(user)
    raise ActiveRecord::RecordNotFound unless email.present? && email.casecmp?(user.email)

    update!(profile: user.profiles.find_or_create_by!(profile_type: "user"))
  end

  private

  def respond!(status)
    transaction do
      update!(status:, responded_at: Time.current)
      notification&.mark_as_read!
    end
  end

  def normalize_email
    self.email = email.to_s.strip.downcase.presence
    self.email ||= profile&.user&.email
  end

  def recipient_must_be_present
    errors.add(:base, "A profile or email address is required") if profile.nil? && email.blank?
  end

  def job_must_be_invitable
    return if job&.is_active? && job&.published?

    errors.add(:job, "must be an active published job")
  end

  def inviter_must_own_job_company
    return if job&.company&.is_owner?(invited_by)

    errors.add(:invited_by, "must own the job's company")
  end
end
