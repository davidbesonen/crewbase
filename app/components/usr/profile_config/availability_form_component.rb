# frozen_string_literal: true

class Usr::ProfileConfig::AvailabilityFormComponent < ApplicationComponent
  extend Dry::Initializer

  option :profile
  option :start_month, optional: true
  option :ical_feed_error, optional: true
  option :show_navigation, default: proc { true }
  option :show_completed_profile_navigation, default: proc { false }
  option :show_embedded_sync_form, default: proc { true }
  option :embedded_in_profile_form, default: proc { false }
  option :source, optional: true

  def before_render
    @calendar_events = profile.calendar_events.where(event_type: "blockout").pluck(:to_date, :id).to_h.transform_keys { |value| value.to_date.strftime("%Y-%m-%d") }
  end

  def month_start
    @month_start ||= (start_month || Date.current).beginning_of_month
  end

  def current_month_start
    @current_month_start ||= Date.current.beginning_of_month
  end

  def max_month_start
    @max_month_start ||= current_month_start.advance(months: 12)
  end

  def previous_month_start
    [ month_start.prev_month.beginning_of_month, current_month_start ].max
  end

  def next_month_start
    [ month_start.next_month.beginning_of_month, max_month_start ].min
  end

  def previous_month_disabled?
    month_start <= current_month_start
  end

  def next_month_disabled?
    month_start >= max_month_start
  end

  def month_end
    @month_end ||= month_start.end_of_month
  end

  def range_start
    @range_start ||= month_start.beginning_of_week(:sunday)
  end

  def range_end
    @range_end ||= month_end.end_of_week(:sunday)
  end

  def weeks
    @weeks ||= (range_start..range_end).to_a.in_groups_of(7)
  end

  def sync_error
    ical_feed_error.presence || (profile.ical_sync_error.presence if profile.respond_to?(:ical_sync_error))
  end

  def sync_attempted_at
    profile.ical_sync_attempted_at if profile.respond_to?(:ical_sync_attempted_at)
  end
end
