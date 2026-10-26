class CrewNetwork
  Row = Data.define(:profile, :connection, :credits)
  TABS = %w[connections worked_together requests].freeze

  def initialize(user:)
    @user = user
  end

  def rows(tab:, query: nil)
    rows = if tab == "worked_together"
      WorkedTogether.new(user: @user).results.map do |row|
        Row.new(profile: row.profile, connection: connections_by_user[row.profile.user_id], credits: row.credits)
      end
    else
      connections.filter_map do |connection|
        next unless tab == "requests" ? connection.pending? : connection.accepted?

        profile = connection.other_user(@user).profiles.detect { |item| item.profile_type == "user" && item.completed_at }
        Row.new(profile:, connection:, credits: []) if profile
      end
    end
    blocked_ids = UserBlock.blocked_ids_for(@user)
    rows.reject! { |row| blocked_ids.include?(row.profile.user_id) }
    return rows if query.blank?

    rows.select do |row|
      [ row.profile.user.full_name, row.profile.headline, *row.profile.occupations.map(&:name),
        *row.profile.locations.flat_map { |location| [ location.city, location.state ] } ].compact.join(" ").downcase.include?(query.downcase)
    end
  end

  def pending_count
    connections.count { |connection| connection.pending? && connection.recipient_id == @user.id }
  end

  private

  def connections
    @connections ||= NetworkConnection.involving(@user)
      .includes(sender: { profiles: [ :occupations, :locations ] }, recipient: { profiles: [ :occupations, :locations ] })
      .order(updated_at: :desc, id: :desc).to_a
  end

  def connections_by_user
    @connections_by_user ||= connections.index_by { |connection| connection.other_user(@user).id }
  end
end
