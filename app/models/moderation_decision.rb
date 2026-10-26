class ModerationDecision < ApplicationRecord
  belongs_to :safety_report
  belongs_to :moderator, class_name: "User"
  validates :notes, presence: true, length: { maximum: 5_000 }
  validates :status, :previous_status, inclusion: { in: SafetyReport.statuses.keys }
  validate :moderator_is_admin

  private

  def moderator_is_admin
    errors.add(:moderator, "must be an administrator") unless moderator&.site_admin?
  end
end
