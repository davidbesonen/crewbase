class ContextualMessage < ApplicationRecord
  belongs_to :conversation, touch: true
  belongs_to :sender, class_name: "User"
  has_many :notifications, as: :notifiable, dependent: :destroy

  has_many_attached :files

  validates :body, length: { maximum: 5_000 }
  validate :content_must_be_present
  validate :files_must_be_safe

  def system?
    event_key.present?
  end

  def preview
    body.presence || "Shared #{files.size} #{'file'.pluralize(files.size)}"
  end

  private

  def content_must_be_present
    errors.add(:body, "or a file is required") if body.blank? && files.empty?
  end

  def files_must_be_safe
    files.each { |file| UploadPolicy.validate(self, :files, file.blob) }
  end
end
