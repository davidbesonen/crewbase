class CompleteQuickStart
  INTENTS = { "find_work" => "Find work", "hire_crew" => "Hire crew", "both" => "Both" }.freeze
  include ActiveModel::Model
  attr_accessor :user, :intent, :occupation_ids

  validates :intent, inclusion: { in: INTENTS.keys }
  validate :known_occupations

  def call
    return false unless valid?

    User.transaction do
      profile = user.profiles.find_or_create_by!(profile_type: "user")
      profile.occupations = occupations if intent != "hire_crew" && occupation_ids.present?
      user.update!(onboarding_intent: intent, onboarding_completed_at: user.onboarding_completed_at || Time.current)
      ProductEvent.record(user:, name: "onboarding_completed", event_key: "once")
    end
    true
  end

  private

  def occupations
    @occupations ||= Occupation.where(id: Array(occupation_ids).compact_blank).to_a
  end

  def known_occupations
    ids = Array(occupation_ids).compact_blank.map(&:to_s).uniq
    errors.add(:occupation_ids, "contain an unavailable occupation") if ids.size > 8 || occupations.map { |occupation| occupation.id.to_s }.sort != ids.sort
  end
end
