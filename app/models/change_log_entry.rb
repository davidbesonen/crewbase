class ChangeLogEntry < ApplicationRecord
  validates :title, :summary, presence: true

  scope :published, -> { where(published_at: ..Time.current).order(published_at: :desc, id: :desc) }

  def published?
    published_at.present? && published_at <= Time.current
  end
end
