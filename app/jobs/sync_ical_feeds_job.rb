# frozen_string_literal: true

class SyncIcalFeedsJob < ApplicationJob
  queue_as :calendar_sync

  def perform
    Profile.where.not(ical_feed_url: [ nil, "" ]).find_each do |profile|
      FetchIcalFeedJob.perform_later(profile.id)
    end
  end
end
