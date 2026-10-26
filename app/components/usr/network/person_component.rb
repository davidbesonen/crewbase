class Usr::Network::PersonComponent < ApplicationComponent
  renders_one :actions

  def initialize(profile:, credits: [], connection: nil)
    @profile, @credits, @connection = profile, credits, connection
  end

  private

  attr_reader :profile, :credits, :connection

  def subtitle
    profile.headline.presence || profile.occupations.map(&:name).first(3).join(" · ").presence || "Crewbase member"
  end

  def location
    profile.locations.map { |item| [ item.city, item.state ].compact_blank.join(", ") }.compact_blank.first
  end
end
