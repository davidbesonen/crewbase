class Usr::Network::RequestFormComponent < ApplicationComponent
  def initialize(profile:, connection:)
    @profile, @connection = profile, connection
  end

  private

  attr_reader :profile, :connection
end
