class Project < ApplicationRecord
  belongs_to :company
  has_many :jobs, dependent: :nullify
  has_many :credits, dependent: :nullify

  enum :status, {
    planning: 0,
    active: 1,
    completed: 2,
    canceled: 3
  }

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  validates :name, presence: true
  validate :ends_on_must_not_precede_starts_on

  def archived? = archived_at.present?

  def archive!
    update!(archived_at: Time.current)
  end

  def restore!
    update!(archived_at: nil)
  end

  private

  def ends_on_must_not_precede_starts_on
    return if starts_on.blank? || ends_on.blank? || ends_on >= starts_on

    errors.add(:ends_on, "must be on or after the start date")
  end
end
