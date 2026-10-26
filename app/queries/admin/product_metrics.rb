class Admin::ProductMetrics
  def initialize(since: 30.days.ago)
    @since = since
  end

  def results
    {
      events: events.group(:name).count,
      members: events.group(:name).distinct.count(:user_id),
      dismissal_reasons: RecommendationFeedback.where(created_at: since..).group(:reason).count,
      recommended_applications: attributed_count("application_submitted"),
      recommended_bookings: attributed_count("offer_accepted")
    }
  end

  private

  attr_reader :since

  def events
    ProductEvent.where(created_at: since..)
  end

  def attributed_count(name)
    events.where(name:).where(<<~SQL.squish).count
      EXISTS (
        SELECT 1 FROM product_events impressions
        WHERE impressions.name = 'recommendation_shown'
          AND impressions.user_id = product_events.user_id
          AND impressions.job_id = product_events.job_id
          AND impressions.created_at <= product_events.created_at
          AND impressions.created_at >= product_events.created_at - INTERVAL '30 days'
      )
    SQL
  end
end
