# frozen_string_literal: true

require "digest"
require "open-uri"
require "resolv"

class IcalFeedSynchronizer
  Result = Data.define(:success?, :error)
  MAX_FEED_BYTES = 2.megabytes
  MAX_EVENT_DAYS = 3_660
  MAX_BLOCKOUTS = 10_000

  def initialize(profile:, fetcher: nil)
    @profile = profile
    @fetcher = fetcher || method(:fetch)
  end

  def call
    attempted_at = Time.current
    feed = @fetcher.call(profile.normalized_ical_feed_url)
    ensure_feed_size!(feed.bytesize)
    calendars = Icalendar::Calendar.parse(feed)
    raise ArgumentError, "Feed does not contain a calendar." if calendars.empty?
    attributes = calendars.flat_map(&:events).each_with_object([]) do |event, rows|
      rows.concat(blockout_attributes(event))
      raise ArgumentError, "Calendar contains too many blockout days (maximum #{MAX_BLOCKOUTS})." if rows.size > MAX_BLOCKOUTS
    end

    profile.transaction do
      sync_events(attributes)
      profile.update!(
        ical_last_synced_at: attempted_at,
        ical_sync_attempted_at: attempted_at,
        ical_sync_error: nil
      )
    end

    Result.new(success?: true, error: nil)
  rescue StandardError => error
    message = "#{error.class}: #{error.message}".truncate(1_000)
    profile.update_columns(ical_sync_attempted_at: Time.current, ical_sync_error: message)
    Rails.logger.error("iCal sync failed for profile #{profile.id}: #{message}")
    Result.new(success?: false, error: message)
  end

  private

  attr_reader :profile

  def fetch(url)
    ensure_public_host!(URI.parse(url).host)
    # open-uri downloads before yielding its stream. Check progress as well as
    # Content-Length so absent or dishonest headers cannot bypass the limit.
    URI.open(url, open_timeout: 5, read_timeout: 10, redirect: false,
      content_length_proc: method(:ensure_feed_size!), progress_proc: method(:ensure_feed_size!)) { |stream| stream.read(MAX_FEED_BYTES + 1) }
  end

  def ensure_feed_size!(bytes)
    raise ArgumentError, "Calendar feed is too large (maximum 2 MB)." if bytes && bytes > MAX_FEED_BYTES
  end

  def ensure_public_host!(host)
    addresses = Resolv.getaddresses(host)
    raise URI::InvalidURIError, "calendar host could not be resolved" if addresses.empty?

    unsafe = addresses.any? do |address|
      ip = IPAddr.new(address)
      ip.private? || ip.loopback? || ip.link_local?
    end
    raise URI::InvalidURIError, "calendar host must resolve to a public address" if unsafe
  end

  def sync_events(attributes)
    external_ids = attributes.map { |item| item.fetch(:external_id) }
    profile.calendar_events.ical.where.not(external_id: external_ids).delete_all

    attributes.each do |item|
      profile.calendar_events.find_or_initialize_by(
        provider: :ical,
        external_id: item.fetch(:external_id)
      ).update!(item.except(:external_id).merge(event_type: "blockout"))
    end
  end

  def blockout_attributes(event)
    return [] if text(event.status).upcase == "CANCELLED" || text(event.transp).upcase == "TRANSPARENT"

    dates = event_dates(event).select { |date| date >= Time.zone.today }
    uid = text(event.uid).presence || Digest::SHA256.hexdigest(event.to_ical)
    name = text(event.summary).presence || "Calendar blockout"

    dates.map do |date|
      {
        external_id: "#{uid}:#{date.iso8601}",
        name: name,
        from_date: date.beginning_of_day,
        to_date: date.end_of_day
      }
    end
  end

  def event_dates(event)
    starts_at = time_value(event.dtstart)
    return [] unless starts_at

    ends_at = time_value(event.dtend) || starts_at
    first_date = starts_at.to_date
    last_date = ends_at.to_date
    last_date -= 1 if date_value?(event.dtstart) && date_value?(event.dtend) && last_date > first_date
    raise ArgumentError, "Calendar event date range is too large (maximum #{MAX_EVENT_DAYS} days)." if last_date - first_date >= MAX_EVENT_DAYS
    (first_date..last_date).to_a
  end

  def time_value(property)
    return unless property

    property.respond_to?(:to_time) ? property.to_time : Time.zone.parse(property.to_s)
  end

  def date_value?(property)
    property&.value.is_a?(Date) && !property.value.is_a?(DateTime)
  end

  def text(property)
    property.respond_to?(:to_str) ? property.to_str : property.to_s
  end
end
