class User < ApplicationRecord
  # Add only the modules you want:
  # :confirmable, :lockable, :timeoutable, :trackable, :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  has_many :assignments, dependent: :destroy
  has_many :roles, through: :assignments

  has_many :visits, dependent: :destroy

  validates :first_name, presence: true
  validates :last_name, presence: true

  class << self
    def ransackable_attributes(auth_object = nil)
      %w[first_name last_name email created_at updated_at]
    end
  end

  # Returns the full name of the user
  def full_name
    "#{first_name} #{last_name}"
  end

  def picks
    pick_sets.includes(:picks)
  end

  def has_role?(role_name)
    roles.exists?(name: role_name)
  end

  def owned_leagues
    leagues.where(league_assignments: { is_owner: true })
  end

  def current_league_pick_set(league)
    pick_sets&.where(league_id: league.id).first || nil
  end
end
