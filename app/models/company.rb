class Company < ApplicationRecord
  include ImageUploader::Attachment(:image)

  has_many :company_assignments, dependent: :destroy
  has_many :users, through: :company_assignments

  has_many :company_plans, dependent: :destroy
  has_many :plans, through: :company_plans

  has_many :jobs, dependent: :destroy
  has_many :credits, dependent: :nullify
  has_many :projects, dependent: :destroy
  has_many :crew_shortlists, dependent: :destroy

  has_many :location_assignments, as: :locationable, dependent: :destroy
  has_many :locations, through: :location_assignments

  has_many :reviews, as: :reviewable, dependent: :destroy
  has_many :industry_assignments, as: :assignable, dependent: :destroy
  has_many :industries, -> { distinct }, through: :industry_assignments

  validates :name, presence: true, uniqueness: true
  validates :contact_email, presence: true
  validates :industries, presence: true
  validates :stripe_customer_id, uniqueness: true, allow_nil: true

  accepts_nested_attributes_for :locations

  ROLES = %w[owner employee].freeze

  EMPLOYEE_RANGES = [
    "1-10",
    "11-50",
    "51-200",
    "201-500",
    "501-1000",
    "1001-5000",
    "5001-10,000",
    "10,001+"
  ].freeze

  # --- DESCRIPTION ---
  # Users are joined to a Company via CompanyAssignment (current employees) and Experience (past employees)

  def owner
    company_assignments.find_by(role: "owner")&.user
  end

  def current_plan
    if new_record?
      return company_plans
        .select { |company_plan| company_plan.status.blank? || company_plan.entitled? }
        .max_by { |company_plan| [ company_plan.created_at || Time.at(0), company_plan.id || 0 ] }
        &.plan
    end

    company_plans.current.first&.plan
  end

  def is_owner?(user)
    owner == user
  end

  def industry
    industries.first
  end

  def overall_rating
    reviews.average(:overall_rating)&.round(1) || 0.0
  end

  def ratings
    # [ "Communication/Clarity", "communication_clarity" ],
    # [ "Payment Timeliness", "payment_timeliness" ],
    # [ "Working Conditions/Safety", "working_conditions_safety" ],
    # [ "Professionalism/Respect", "professionalism_respect" ],
    # [ "Accuracy of Call/Scope (was the gig described correctly?)", "accuracy_of_call_scope" ]

    categories = %w[
      communication_clarity
      payment_timeliness
      working_conditions_safety
      professionalism_respect
      accuracy_of_call_scope
    ]

    company_reviews = reviews
    if company_reviews.none?
      return categories.index_with { 0.0 }.merge("overall_rating" => 0.0)
    end

    totals = Hash.new(0.0)
    review_count = company_reviews.count

    company_reviews.find_each do |review|
      categories.each do |category|
        totals[category] += review.rating_data[category].to_f
      end
    end

    ratings = categories.index_with do |category|
      (totals[category] / review_count).round(1)
    end

    overall_rating = company_reviews.average(:overall_rating)&.to_f || 0.0
    ratings.merge("overall_rating" => overall_rating.round(1))
  end

  def employees
    company_assignments.includes(:user).map(&:user)
  end

  def employee_range
    employee_count = employees.size
    return "N/A" unless employee_count.present?

    EMPLOYEE_RANGES.find do |range|
      min, max = range.split("-").map { |num| num.delete(",").to_i }
      if max
        employee_count >= min && employee_count <= max
      else
        employee_count >= min
      end
    end
  end

  def formatted_location
    locations.map do |loc|
      state_part = loc.state.present? ? " #{loc.state}" : ""
      "#{loc.city},#{state_part} #{loc.country}"
    end.join(" / ")
  end

  def normalized_website_url
    return if website_url.blank?
    return website_url if website_url.match?(/\Ahttps?:\/\//i)

    "https://#{website_url}"
  end

  def primary_industry
    industries.order(:name).first
  end

  def industry_names
    industries.order(:name).pluck(:name)
  end

  def industry_names_text
    industry_names.to_sentence
  end

  class << self
    def ransackable_attributes(auth_object = nil)
      %w[created_at founded_at id is_public name]
    end

    def ransackable_associations(auth_object = nil)
      %w[industries industry_assignments jobs locations]
    end
  end
end
