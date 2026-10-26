class SafetyReport < ApplicationRecord
  CATEGORIES = { "harassment" => "Harassment or unwanted contact", "spam" => "Spam or misleading content",
    "incorrect_credit" => "Incorrect work credit", "incorrect_review" => "Incorrect or unfair review", "other" => "Other concern" }.freeze
  belongs_to :reporter, class_name: "User"
  belongs_to :subject, polymorphic: true
  has_many :moderation_decisions, dependent: :restrict_with_error
  enum :status, { open: "open", resolved: "resolved", dismissed: "dismissed" }, prefix: false
  validates :subject_type, inclusion: { in: %w[Profile Credit Review Conversation Job Company] }
  validates :category, inclusion: { in: CATEGORIES.keys }
  validates :details, presence: true, length: { maximum: 5_000 }
  validates :subject_label, presence: true
end
