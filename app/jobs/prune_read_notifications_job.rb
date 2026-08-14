# frozen_string_literal: true

class PruneReadNotificationsJob < ApplicationJob
  RETENTION_PERIOD = 30.days

  queue_as :maintenance

  def perform
    Notification.read_before(RETENTION_PERIOD.ago).in_batches.delete_all
  end
end
