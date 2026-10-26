class Usr::JobOffer::InboxComponent < ApplicationComponent
  def initialize(summaries:, counts:, view:, query:)
    @summaries, @counts, @view, @query = summaries, counts, view, query
  end

  def empty_title
    return "No offers yet" if @counts.fetch("all").zero?
    return "No offers match your search" if @query.present?

    { "needs_reply" => "You’re all caught up", "sent" => "No offers awaiting crew", "confirmed" => "No upcoming bookings", "history" => "No past offers" }.fetch(@view, "No offers found")
  end
end
