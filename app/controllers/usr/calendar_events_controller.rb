class Usr::CalendarEventsController < ApplicationController
  before_action :set_profile

  def create
    date = parse_date(params[:date])
    return render json: { error: "Invalid date" }, status: :unprocessable_entity if date.nil?

    external_id = date.strftime("%-m/%-d/%Y")
    event = @profile.calendar_events.find_or_initialize_by(provider: "manual", external_id: external_id)
    event.from_date ||= date.in_time_zone
    event.to_date ||= date.in_time_zone

    if event.save
      render json: { status: "created", date: external_id }
    else
      render json: { error: event.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def destroy
    date = parse_date(params[:date])
    return render json: { error: "Invalid date" }, status: :unprocessable_entity if date.nil?

    external_id = date.strftime("%-m/%-d/%Y")
    event = @profile.calendar_events.find_by(provider: "manual", external_id: external_id)
    event&.destroy

    render json: { status: "deleted", date: external_id }
  end

  def toggle_date_selection
    @date = parse_iso_date(params[:date])
    return head :unprocessable_entity if @date.nil?

    @month_start = parse_month(params[:month]) || Date.current.beginning_of_month

    if params[:toggle_action] == "add"
      @profile.calendar_events.create(provider: "manual", external_id: @date.strftime("%-m/%-d/%Y"), to_date: @date.beginning_of_day, event_type: "blockout")
    elsif params[:toggle_action] == "remove"
      @calendar_event = @profile.calendar_events.find(params[:calendar_event_id])
      @calendar_event.destroy
    end

    @calendar_events = @profile.calendar_events.where(event_type: "blockout").pluck(:to_date, :id).to_h.transform_keys { |value| value.to_date.strftime("%Y-%m-%d") }
    @calendar_events_sorted = @calendar_events.sort_by { |date_str, _| Date.parse(date_str) }
  end

  def destroy_all
    @month_start = parse_month(params[:month]) || Date.current.beginning_of_month
    current_month_start = Date.current.beginning_of_month
    max_month_start = current_month_start.advance(months: 12)
    @previous_month_disabled = @month_start <= current_month_start
    @next_month_disabled = @month_start >= max_month_start
    range_start = @month_start.beginning_of_week(:sunday)
    range_end = @month_start.end_of_month.end_of_week(:sunday)
    @weeks = (range_start..range_end).to_a.in_groups_of(7)

    @profile.calendar_events.where(event_type: "blockout").destroy_all
    @calendar_events = @profile.calendar_events.where(event_type: "blockout").pluck(:to_date, :id).to_h.transform_keys { |value| value.to_date.strftime("%Y-%m-%d") }
    @calendar_events_sorted = @calendar_events.sort_by { |date_str, _| Date.parse(date_str) }
  end

  def previous_month
    month = parse_month(params[:month]) || Date.current.beginning_of_month
    current_month_start = Date.current.beginning_of_month
    max_month_start = current_month_start.advance(months: 12)
    @month_start = [ month.prev_month.beginning_of_month, current_month_start ].max
    @previous_month_disabled = @month_start <= current_month_start
    @next_month_disabled = @month_start >= max_month_start
    range_start = @month_start.beginning_of_week(:sunday)
    range_end = @month_start.end_of_month.end_of_week(:sunday)
    @weeks = (range_start..range_end).to_a.in_groups_of(7)
    @calendar_events = @profile.calendar_events.where(event_type: "blockout").pluck(:to_date, :id).to_h.transform_keys { |value| value.to_date.strftime("%Y-%m-%d") }
  end

  def next_month
    month = parse_month(params[:month]) || Date.current.beginning_of_month
    current_month_start = Date.current.beginning_of_month
    max_month_start = current_month_start.advance(months: 12)
    @month_start = [ month.next_month.beginning_of_month, max_month_start ].min
    @previous_month_disabled = @month_start <= current_month_start
    @next_month_disabled = @month_start >= max_month_start
    range_start = @month_start.beginning_of_week(:sunday)
    range_end = @month_start.end_of_month.end_of_week(:sunday)
    @weeks = (range_start..range_end).to_a.in_groups_of(7)
    @calendar_events = @profile.calendar_events.where(event_type: "blockout").pluck(:to_date, :id).to_h.transform_keys { |value| value.to_date.strftime("%Y-%m-%d") }
  end

  private

  def set_profile
    @profile = current_user.profiles.find(params[:profile_id])
  end

  def parse_date(value)
    return nil if value.blank?

    value.include?("/") ? Date.strptime(value, "%m/%d/%Y") : Date.iso8601(value)
  rescue Date::Error
    nil
  end

  def parse_month(value)
    return nil if value.blank?

    Date.parse(value).beginning_of_month
  rescue ArgumentError
    nil
  end

  def parse_iso_date(value)
    return nil if value.blank?

    Date.iso8601(value)
  rescue Date::Error
    nil
  end
end
