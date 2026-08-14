class Profile < ApplicationRecord
  require "ipaddr"
  require "uri"
  belongs_to :user

  has_many :job_applications, dependent: :destroy
  has_many :job_invitations, dependent: :destroy
  has_many :crew_assignments, dependent: :destroy
  has_many :crew_positions, through: :crew_assignments
  has_many :experiences, dependent: :destroy
  has_many :credits, dependent: :destroy
  has_many :calendar_events, dependent: :destroy

  validate :ical_feed_url_must_be_public
  has_many :crew_shortlist_memberships, dependent: :destroy
  has_many :crew_shortlists, through: :crew_shortlist_memberships

  has_many :company_assignments, dependent: :destroy
  has_many :companies, through: :company_assignments

  has_many :equipment_assignments, dependent: :destroy
  has_many :equipment, through: :equipment_assignments

  has_many :location_assignments, as: :locationable, dependent: :destroy
  has_many :locations, through: :location_assignments

  has_many :occupation_assignments, as: :assignable, dependent: :destroy
  has_many :occupations, through: :occupation_assignments

  has_many :skill_assignments, dependent: :destroy
  has_many :skills, through: :skill_assignments

  has_many :authored_reviews, class_name: "Review", foreign_key: :profile_id, dependent: :destroy
  has_many :received_reviews, as: :reviewable, class_name: "Review", dependent: :destroy

  accepts_nested_attributes_for :locations
  accepts_nested_attributes_for :experiences, allow_destroy: true, reject_if: proc { |attributes|
    attributes["title"].blank? &&
      attributes["company_name"].blank? &&
      attributes["summary"].blank? &&
      attributes["start_year"].blank? &&
      attributes["end_year"].blank?
  }

  def normalized_ical_feed_url
    ical_feed_url.to_s.sub(/\Awebcal:\/\//i, "https://")
  end

  PROFILE_TYPES = %w[user company_owner].freeze
  COMPLETION_STEPS = [
    { key: :location, label: "Add Location", weight: 15, anchor: "location_form" },
    { key: :occupations, label: "Add Occupations", weight: 20, anchor: "occupation_form" },
    { key: :skills, label: "Add Skills & Equipment", weight: 15, anchor: "skill_equipment_form" },
    { key: :bio, label: "Add Bio", weight: 15, anchor: "bio_form" },
    { key: :experience, label: "Add Experience", weight: 15, anchor: "experience_form" },
    { key: :online_presence, label: "Add Online Presence", weight: 10, anchor: "online_presence_form" },
    { key: :availability, label: "Add Availability", weight: 10, anchor: "availability_form" }
  ].freeze
  ONLINE_PRESENCE_FIELDS = %i[
    website_url linkedin_url twitter_handle instagram_handle spotify_profile_url
  ].freeze

  class << self
    def ransackable_attributes(auth_object = nil)
      %w[completed_at created_at headline profile_type updated_at user_id]
    end

    def ransackable_associations(auth_object = nil)
      %w[locations occupations skills user]
    end
  end

  def primary_location
    locations.first
  end

  def formatted_headline
    self.headline.presence || self.occupations.limit(2).pluck(:name).to_sentence.presence || "Crewbase Member"
  end

  def formatted_location
    [ self.primary_location&.city, self.primary_location&.state ].compact_blank.join(", ").presence || self.primary_location&.country.presence || "Location not listed"
  end

  def completion_percentage
    COMPLETION_STEPS.sum { |step| completion_step_complete?(step.fetch(:key)) ? step.fetch(:weight) : 0 }
  end

  def complete?
    completion_percentage == 100
  end

  def next_completion_step
    COMPLETION_STEPS.find { |step| !completion_step_complete?(step.fetch(:key)) }
  end

  def availability_overview
    blocked_dates = upcoming_blockout_dates

    {
      status: availability_status,
      blocked_days: blocked_dates.size,
      next_blockout_date: blocked_dates.first
    }
  end

  private

  def ical_feed_url_must_be_public
    return if ical_feed_url.blank?

    uri = URI.parse(normalized_ical_feed_url)
    valid = uri.is_a?(URI::HTTP) && uri.host.present? && uri.userinfo.blank?
    valid &&= uri.host != "localhost" && public_ip_literal?(uri.host)
    errors.add(:ical_feed_url, "must be a public HTTP or HTTPS URL") unless valid
  rescue URI::InvalidURIError
    errors.add(:ical_feed_url, "must be a public HTTP or HTTPS URL")
  end

  def public_ip_literal?(host)
    address = IPAddr.new(host)
    !address.private? && !address.loopback? && !address.link_local?
  rescue IPAddr::InvalidAddressError
    true
  end

  def completion_step_complete?(key)
    case key
    when :location
      locations.any? { |location| location.city.present? || location.country.present? }
    when :occupations
      occupations.any?
    when :skills
      skills.any? || equipment.any?
    when :bio
      bio.present?
    when :experience
      experiences.any?
    when :online_presence
      ONLINE_PRESENCE_FIELDS.any? { |field| public_send(field).present? }
    when :availability
      ical_feed_url.present? || future_blockout_events.exists?
    end
  end

  def availability_status
    return "Calendar connected" if ical_feed_url.present?
    return "Blockout dates added" if future_blockout_events.exists?

    "No availability added"
  end

  def future_blockout_events
    calendar_events
      .where(event_type: "blockout")
      .where("COALESCE(to_date, from_date) >= ?", Date.current.beginning_of_day)
  end

  def upcoming_blockout_dates
    range = Date.current..30.days.from_now.to_date

    future_blockout_events.filter_map do |event|
      starts_on = event.from_date&.to_date || event.to_date&.to_date
      ends_on = event.to_date&.to_date || starts_on
      next if starts_on.blank? || ends_on.blank?

      ([ starts_on, range.begin ].max..[ ends_on, range.end ].min).to_a
    end.flatten.uniq.sort
  end
end
