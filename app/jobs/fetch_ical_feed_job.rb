# frozen_string_literal: true

class FetchIcalFeedJob < ApplicationJob
  queue_as :calendar_sync

  def perform(profile_id)
    profile = Profile.find_by(id: profile_id)
    return unless profile&.ical_feed_url.present?

    IcalFeedSynchronizer.new(profile: profile).call
  end
end
