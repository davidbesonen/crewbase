class Credit < ApplicationRecord
  belongs_to :profile
  belongs_to :job, optional: true
  belongs_to :project, optional: true
  belongs_to :company, optional: true

  validates :role, :project_name, presence: true
  validate :ends_on_must_not_precede_starts_on

  scope :display_order, -> { order(starts_on: :desc, created_at: :desc) }

  def display_company
    company&.name.presence || company_name.presence
  end

  def display_dates
    return "Date not listed" if starts_on.blank? && ends_on.blank?
    return starts_on.to_fs(:long) if starts_on.present? && (ends_on.blank? || ends_on == starts_on)

    [ starts_on&.to_fs(:long), ends_on&.to_fs(:long) ].compact.join(" – ")
  end

  def verified?
    verified_at.present?
  end

  private

  def ends_on_must_not_precede_starts_on
    return if starts_on.blank? || ends_on.blank? || ends_on >= starts_on

    errors.add(:ends_on, "must be on or after the start date")
  end
end
