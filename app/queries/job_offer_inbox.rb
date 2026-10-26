class JobOfferInbox
  VIEWS = { "all" => "All", "needs_reply" => "Needs your reply", "sent" => "Awaiting crew", "confirmed" => "Confirmed", "history" => "History" }.freeze
  attr_reader :view, :query

  def initialize(user:, view: nil, query: nil)
    @user = user
    @view = VIEWS.key?(view) ? view : "all"
    @query = query.to_s.strip.first(100)
  end

  def counts
    @counts ||= scopes.transform_values(&:count)
  end

  def results
    scope = scopes.fetch(view)
    if query.present?
      scope = scope.joins(job_application: { job: :company }).joins(profile: :user)
        .where("job_offers.role ILIKE :q OR companies.name ILIKE :q OR users.first_name ILIKE :q OR users.last_name ILIKE :q",
          q: "%#{JobOffer.sanitize_sql_like(query)}%")
    end
    scope = if %w[needs_reply sent].include?(view)
      scope.order(Arel.sql("job_offers.expires_at ASC NULLS LAST"))
    elsif view == "confirmed"
      scope.order(starts_at: :asc)
    else
      scope
    end
    scope.includes({ profile: :user }, job_application: { job: :company }).order(created_at: :desc, id: :desc)
  end

  private

  def scopes
    @scopes ||= begin
      all = JobOffer.visible_to(@user)
      pending = all.awaiting_response
      confirmed = all.current_bookings
      {
        "all" => all,
        "needs_reply" => pending.where(profile_id: @user.user_profile&.id),
        "sent" => pending.where(jobs: { company_id: @user.owned_companies.select(:id) }),
        "confirmed" => confirmed,
        "history" => all.where.not(id: pending.select(:id)).where.not(id: confirmed.select(:id))
      }
    end
  end
end
