# frozen_string_literal: true

namespace :jobs do
  desc "Run the Solid Queue supervisor and workers"
  task work: :environment do
    require "solid_queue/cli"

    SolidQueue::Cli.start([])
  end

  desc "Queue synchronization for all connected calendar feeds"
  task sync_calendars: :environment do
    SyncIcalFeedsJob.perform_later
  end
end
