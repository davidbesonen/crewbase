class Job < ApplicationRecord
  include Compensated

  belongs_to :company, optional: true
  belongs_to :project, optional: true

  has_many :job_applications, dependent: :destroy
  has_many :credits, dependent: :nullify
  has_many :job_invitations, dependent: :destroy
  has_many :crew_positions, dependent: :destroy
  has_many :crew_assignments, through: :crew_positions
  has_many :saved_jobs, dependent: :destroy
  has_many :saving_users, through: :saved_jobs, source: :user
  has_many :job_requirements, dependent: :destroy
  has_many :required_occupation_requirements,
    -> { required.where(requirement_type: "Occupation") },
    class_name: "JobRequirement"
  has_many :required_occupations,
    through: :required_occupation_requirements,
    source: :requirement,
    source_type: "Occupation"
  has_many :required_skill_requirements,
    -> { required.where(requirement_type: "Skill") },
    class_name: "JobRequirement"
  has_many :required_skills,
    through: :required_skill_requirements,
    source: :requirement,
    source_type: "Skill"
  has_many :preferred_skill_requirements,
    -> { preferred.where(requirement_type: "Skill") },
    class_name: "JobRequirement"
  has_many :preferred_skills,
    through: :preferred_skill_requirements,
    source: :requirement,
    source_type: "Skill"
  has_many :required_equipment_requirements,
    -> { required.where(requirement_type: "Equipment") },
    class_name: "JobRequirement"
  has_many :required_equipment,
    through: :required_equipment_requirements,
    source: :requirement,
    source_type: "Equipment"
  has_many :preferred_equipment_requirements,
    -> { preferred.where(requirement_type: "Equipment") },
    class_name: "JobRequirement"
  has_many :preferred_equipment,
    through: :preferred_equipment_requirements,
    source: :requirement,
    source_type: "Equipment"

  has_many :location_assignments, as: :locationable, dependent: :destroy
  has_many :locations, through: :location_assignments

  accepts_nested_attributes_for :locations
  accepts_nested_attributes_for :job_requirements, allow_destroy: true
  accepts_nested_attributes_for :crew_positions, reject_if: :all_blank
  has_rich_text :description

  attribute :questions, default: -> { [] }
  attr_accessor :require_initial_crew_position

  validates :company, :title, :employment_type, :workplace_type, presence: true
  validates :posting_type, presence: { message: "must be selected" }
  validate :description_must_be_present
  validate :project_must_belong_to_company
  validate :work_dates_must_be_within_job_range
  validate :single_role_cannot_have_crew_positions
  validate :new_multi_position_gig_must_have_a_crew_position,
    on: :create,
    if: :require_initial_crew_position

  enum :workplace_type, {
    on_site: 0,
    remote: 1,
    hybrid: 2
  }

  enum :employment_type, {
    contract: 0,
    full_time: 1,
    part_time: 2
  }

  enum :posting_type, {
    single_role: 0,
    multi_position: 1
  }

  enum :status, {
    draft: 0,
    published: 1,
    archived: 2,
    closed: 3,
    filled: 4,
    completed: 5
  }

  scope :upcoming, lambda {
    where(is_active: true, status: :published)
      .where(starts_at: Time.current..)
      .order(:starts_at, :id)
  }

  class << self
    def ransackable_attributes(auth_object = nil)
      %w[
        application_deadline
        archived_at
        closed_at
        company_id
        created_at
        created_by
        editable_by_company
        employment_type
        ends_at
        filled_at
        id
        is_active
        is_visa_sponsorship_available
        pay_max
        pay_min
        pay_period
        published_at
        questions
        requires_travel
        starts_at
        status
        title
        updated_at
        workplace_type
      ]
    end

    def ransackable_associations(auth_object = nil)
      %w[company locations]
    end
  end

  def formatted_location
    return "Remote" if remote?
    return "Location not listed" if locations.empty?

    locations.map { |location| formatted_location_parts(location) }.join(" / ")
  end

  def primary_status_timestamp
    case status
    when "archived"
      archived_at
    when "closed"
      closed_at
    when "filled"
      filled_at
    when "completed"
      completed_at
    else
      published_at
    end
  end

  def relative_published_at(reference_time = Time.current)
    return "Not published" if published_at.blank?

    seconds_ago = [ reference_time - published_at, 0 ].max

    if seconds_ago < 24.hours
      hours = [ (seconds_ago / 1.hour).floor, 1 ].max
      "#{hours} #{'hour'.pluralize(hours)} ago"
    elsif seconds_ago < 7.days
      days = (seconds_ago / 1.day).floor
      "#{days} #{'day'.pluralize(days)} ago"
    else
      weeks = (seconds_ago / 1.week).floor
      weeks = 1 if weeks.zero?
      "#{weeks} #{'week'.pluralize(weeks)} ago"
    end
  end

  def editable_by?(user)
    return false if user.blank?

    company&.is_owner?(user) || created_by == user.id
  end

  def posting_type_label
    multi_position? ? "Multi-position gig" : "Single job posting"
  end

  def plain_description
    description&.to_plain_text.to_s
  end

  def questions=(value)
    normalized_questions = Array(value).map(&:to_s).map(&:strip).reject(&:blank?)
    super(normalized_questions)
  end

  def work_dates=(value)
    normalized_dates = Array(value).filter_map do |date|
      Date.iso8601(date.to_s) if date.present?
    rescue Date::Error
      nil
    end

    super(normalized_dates.uniq.sort)
  end

  private

  def new_multi_position_gig_must_have_a_crew_position
    return unless multi_position?
    return if crew_positions.reject(&:marked_for_destruction?).any?

    errors.add(:crew_positions, "must include at least one position")
  end

  def single_role_cannot_have_crew_positions
    return unless single_role? && crew_positions.any?

    errors.add(:posting_type, "cannot be changed while the gig has crew positions")
  end

  def work_dates_must_be_within_job_range
    return if work_dates.blank?

    outside_range = work_dates.any? do |date|
      (starts_at.present? && date < starts_at.to_date) ||
        (ends_at.present? && date > ends_at.to_date)
    end
    errors.add(:work_dates, "must fall between the job start and end dates") if outside_range
  end

  def project_must_belong_to_company
    return if project.blank? || project.company_id == company_id

    errors.add(:project, "must belong to the job's company")
  end

  def description_must_be_present
    return if plain_description.present?

    errors.add(:description, "can't be blank")
  end

  def formatted_location_parts(location)
    [ location.city, location.state, location.country ].compact_blank.join(", ")
  end
end
