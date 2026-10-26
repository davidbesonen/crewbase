class UserBlock < ApplicationRecord
  belongs_to :blocker, class_name: "User"
  belongs_to :blocked_user, class_name: "User"
  validates :blocked_user_id, uniqueness: { scope: :blocker_id }
  validate :different_people

  def self.between?(first, second)
    return false unless first && second

    where(blocker: first, blocked_user: second).or(where(blocker: second, blocked_user: first)).exists?
  end

  def self.involving(user)
    where(blocker: user).or(where(blocked_user: user))
  end

  def self.blocked_ids_for(user)
    involving(user).pluck(:blocker_id, :blocked_user_id).flatten.uniq - [ user.id ]
  end

  private

  def different_people
    errors.add(:blocked_user, "must be another person") if blocker_id == blocked_user_id
  end
end
