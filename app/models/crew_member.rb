class CrewMember < ApplicationRecord
  INVITATION_LIFETIME = 7.days
  FIELDS = %w[first_name last_name email phone city state country role department years_with_company years_experience skills_text equipment_text notes].freeze
  belongs_to :company
  belongs_to :profile, optional: true
  has_many :crew_holds, dependent: :destroy

  normalizes :email, with: ->(value) { value.to_s.strip.downcase.presence }
  normalizes :phone, with: ->(value) { value.to_s.strip.presence }
  before_validation :normalize_phone
  validates :first_name, :last_name, presence: true, length: { maximum: 100 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :email, :phone, :city, :state, :country, :role, :department, length: { maximum: 255 }
  validates :skills_text, :equipment_text, :notes, length: { maximum: 2000 }
  validates :skills_text, :equipment_text, experience_terms: true
  validates :years_with_company, :years_experience, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :email, :phone_key, :profile_id, uniqueness: { scope: :company_id }, allow_nil: true
  validate :contact_required
  validate :valid_phone

  generates_token_for :claim, expires_in: INVITATION_LIFETIME do
    [ invitation_nonce, email, phone_key, profile_id, invitation_expires_at ]
  end

  def full_name = [ first_name, last_name ].join(" ")
  def location_label = [ city, state, country ].compact_blank.join(", ")
  def invitation_email_matches?(user) = email.blank? || email == user.email.to_s.downcase
  def invitation_active? = invitation_nonce.present? && profile_id.nil? && invitation_expires_at&.future?

  def invitation_token!
    update!(invitation_nonce: SecureRandom.hex(20), invitation_expires_at: INVITATION_LIFETIME.from_now)
    generate_token_for(:claim)
  end

  private

  def normalize_phone
    digits = phone.to_s.gsub(/\D/, "")
    digits = "1#{digits}" if digits.length == 10
    self.phone_key = digits.presence
  end

  def contact_required
    errors.add(:base, "Add an email or phone number") if email.blank? && phone.blank?
  end

  def valid_phone
    errors.add(:phone, "must contain 7 to 15 digits") if phone.present? && !phone_key.to_s.length.between?(7, 15)
    if phone.present? && !phone.match?(/\A\+?[\d\s().-]+\z/)
      errors.add(:phone, "must use digits, spaces, +, parentheses or hyphens; omit extensions")
    end
  end
end
