class JobContract < ApplicationRecord
  MAX_FILE_SIZE = UploadPolicy::MAX_FILE_SIZE
  SUPPORTED_CONTENT_TYPES = UploadPolicy::CONTENT_TYPES

  belongs_to :job
  belongs_to :uploaded_by, class_name: "User"

  has_one_attached :file

  before_validation :use_filename_as_title

  validates :title, presence: true, length: { maximum: 150 }
  validate :file_must_be_attached
  validate { UploadPolicy.validate(self, :file, file.blob) if file.attached? }

  private

  def use_filename_as_title
    self.title = file.filename.to_s if title.blank? && file.attached?
  end

  def file_must_be_attached
    errors.add(:file, "must be selected") unless file.attached?
  end
end
