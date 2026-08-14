class ContextualMessage < ApplicationRecord
  belongs_to :conversation, touch: true
  belongs_to :sender, class_name: "User"
  has_many :notifications, as: :notifiable, dependent: :destroy

  validates :body, presence: true, length: { maximum: 5_000 }
end
