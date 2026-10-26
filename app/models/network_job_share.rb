class NetworkJobShare < ApplicationRecord
  belongs_to :job
  belongs_to :sender, class_name: "User"
  belongs_to :recipient, class_name: "User"
  has_many :notifications, as: :notifiable, dependent: :destroy

  validates :note, length: { maximum: 1000 }
  validates :recipient_id, uniqueness: { scope: [ :job_id, :sender_id ] }
  validate :accepted_connection, on: :create
  validate :open_job, on: :create

  scope :involving, ->(user) { where(sender: user).or(where(recipient: user)) }

  private

  def accepted_connection
    return if sender && recipient && sender != recipient && NetworkConnection.accepted.between(sender, recipient).exists?

    errors.add(:recipient, "must be an accepted connection")
  end

  def open_job
    errors.add(:job, "must be open for applications") unless job&.network_shareable?
  end
end
