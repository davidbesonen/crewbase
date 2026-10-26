class Usr::Network::ConnectionActionsComponent < ApplicationComponent
  def initialize(profile:, connection:, viewer:)
    @profile, @connection, @viewer = profile, connection, viewer
  end

  private

  attr_reader :profile, :connection, :viewer
end
