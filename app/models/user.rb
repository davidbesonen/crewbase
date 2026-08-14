class User < ApplicationRecord
  # Add only the modules you want:
  # :confirmable, :lockable, :timeoutable, :trackable, :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable, :omniauthable, omniauth_providers: [ :google_oauth2 ]

  has_many :assignments, dependent: :destroy
  has_many :roles, through: :assignments

  has_many :company_assignments, dependent: :destroy
  has_many :companies, through: :company_assignments
  has_many :owned_company_assignments,
    -> { where(role: "owner") },
    class_name: "CompanyAssignment"
  has_many :owned_companies,
    through: :owned_company_assignments,
    source: :company

  has_many :profiles, dependent: :destroy
  has_many :notifications, foreign_key: :recipient_id, dependent: :destroy, inverse_of: :recipient
  has_many :conversation_memberships, dependent: :destroy
  has_many :conversations, through: :conversation_memberships
  has_many :contextual_messages, foreign_key: :sender_id, dependent: :restrict_with_error
  has_many :sent_job_invitations, class_name: "JobInvitation", foreign_key: :invited_by_id, dependent: :restrict_with_error

  has_many :visits, dependent: :destroy
  has_many :saved_jobs, dependent: :destroy
  has_many :user_subscriptions, dependent: :destroy
  has_many :user_plans, through: :user_subscriptions
  has_many :bookmarked_jobs, through: :saved_jobs, source: :job
  has_many :created_crew_shortlists,
    class_name: "CrewShortlist",
    foreign_key: :created_by_id,
    dependent: :destroy

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :phone, presence: true, if: :sms_notifications_enabled?

  class << self
    def ransackable_attributes(auth_object = nil)
      %w[first_name last_name email created_at updated_at]
    end

    def ransackable_associations(auth_object = nil)
      %w[assignments companies company_assignments profiles roles visits]
    end

    def from_google(auth)
      email = auth.info.email.downcase
      user = User.find_or_initialize_by(email: email)
      user.provider ||= auth.provider
      user.uid       ||= auth.uid
      user.first_name ||= auth.info.first_name
      user.last_name  ||= auth.info.last_name
      user.password   ||= Devise.friendly_token[0, 20]
      user.save!
      assign_default_role(user)
      ensure_profile(user)
      user
    end

    private

    def assign_default_role(user)
      role = Role.find_by(name: "user")
      user.assignments.find_or_create_by(role: role) if role
    end

    def ensure_profile(user)
      user.profiles.find_or_create_by(profile_type: "user")
    end
  end

  # Returns the full name of the user
  def full_name
    "#{first_name} #{last_name}"
  end

  def initials
    "#{first_name.first}#{last_name.first}".upcase
  end

  def picks
    pick_sets.includes(:picks)
  end

  def has_role?(role_name)
    roles.exists?(name: role_name)
  end

  def user_profile
    profiles.where(profile_type: "user").first
  end

  def has_completed_user_profile?
    profiles.where(profile_type: "user").where.not(completed_at: nil).exists?
  end
end
