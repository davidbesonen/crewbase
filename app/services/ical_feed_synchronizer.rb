# frozen_string_literal: true

require "digest"
require "open-uri"
require "resolv"

class IcalFeedSynchronizer
  Result = Data.define(:success?, :error)

  def initialize(profile:, fetcher: nil)
    @profile = profile
    @fetcher = fetcher || method(:fetch)
  end

  def call
    attempted_at = Time.current
    calendars = Icalendar::Calendar.parse(@fetcher.call(profile.normalized_ical_feed_url))
    attributes = calendars.flat_map(&:events).flat_map { |event| blockout_attributes(event) }

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
    URI.open(url, open_timeout: 5, read_timeout: 10, redirect: false).read
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
