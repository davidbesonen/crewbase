class NetworkConnection < ApplicationRecord
  belongs_to :sender, class_name: "User"
  belongs_to :recipient, class_name: "User"
  has_many :notifications, as: :notifiable, dependent: :destroy

  enum :status, { pending: 0, accepted: 1, declined: 2 }
  validates :introduction, length: { maximum: 500 }
  validate :different_people
  validate :unique_pair, on: :create

  scope :involving, ->(user) { where(sender: user).or(where(recipient: user)) }
  scope :between, ->(first, second) { where(sender: first, recipient: second).or(where(sender: second, recipient: first)) }

  def self.connected_users(user)
    connections = accepted.involving(user)
    User.where(id: connections.where(sender: user).select(:recipient_id))
      .or(User.where(id: connections.where(recipient: user).select(:sender_id)))
  end

  def other_user(user)
    sender_id == user.id ? recipient : sender
  end

  private

  def different_people
    errors.add(:recipient, "must be another person") if sender_id == recipient_id
  end

  def unique_pair
    return unless sender && recipient

    errors.add(:recipient, "already has a connection or request with you") if self.class.between(sender, recipient).exists?
  end
end
