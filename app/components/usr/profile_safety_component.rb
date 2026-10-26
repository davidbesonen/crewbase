class Usr::ProfileSafetyComponent < ApplicationComponent
  def initialize(profile:, block:, blocked:, own_profile:)
    @profile, @block, @blocked, @own_profile = profile, block, blocked, own_profile
  end

  private

  attr_reader :profile, :block, :blocked, :own_profile
end
