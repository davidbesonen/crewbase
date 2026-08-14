class ProcessStripeEvent
  class CustomerMismatch < StandardError; end

  SUBSCRIPTION_EVENTS = %w[customer.subscription.created customer.subscription.updated customer.subscription.deleted].freeze
  INVOICE_EVENTS = { "invoice.paid" => "active", "invoice.payment_failed" => "past_due" }.freeze

  def initialize(event:)
    @event = event
  end

  def call
    stripe_event = find_or_create_event
    return stripe_event if stripe_event.processed_at?

    stripe_event.with_lock do
      return stripe_event if stripe_event.processed_at?

      process_event
      stripe_event.update!(processed_at: Time.current)
    end
    stripe_event
  end

  private

  attr_reader :event

  def find_or_create_event
    StripeEvent.create!(stripe_event_id: event.id, event_type: event.type, payload: event.to_hash)
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    StripeEvent.find_by!(stripe_event_id: event.id)
  end

  def process_event
    object = event.data.object
    case event.type
    when "checkout.session.completed" then process_checkout(object)
    when *SUBSCRIPTION_EVENTS then process_subscription(object)
    when *INVOICE_EVENTS.keys then process_invoice(object, INVOICE_EVENTS.fetch(event.type))
    end
  end

  def process_checkout(session)
    checkout_metadata = metadata(session)
    if checkout_metadata["company_id"].present?
      company = Company.find(checkout_metadata["company_id"])
      assert_customer!(company.stripe_customer_id, value(session, "customer"))
      company.update!(stripe_customer_id: value(session, "customer"))
    end
  end

  def process_subscription(subscription)
    subscription_metadata = metadata(subscription)
    item = Array(value(value(subscription, "items"), "data")).first || {}
    price_id = value(value(item, "price"), "id")

    if subscription_metadata["user_id"].present?
      sync_user_subscription(subscription, subscription_metadata, item, price_id)
    else
      sync_company_subscription(subscription, subscription_metadata, item, price_id)
    end
  end

  def sync_company_subscription(subscription, subscription_metadata, item, price_id)
    company = company_for(subscription, subscription_metadata)
    assert_customer!(company.stripe_customer_id, value(subscription, "customer"))
    plan, interval = company_plan_for_price!(price_id)
    company_plan = company.company_plans.find_by(stripe_subscription_id: value(subscription, "id")) ||
      company.company_plans.where(plan:, stripe_subscription_id: nil).order(created_at: :desc, id: :desc).first ||
      company.company_plans.build(plan:)

    CompanyPlan.transaction do
      company.update!(stripe_customer_id: value(subscription, "customer"))
      assign_subscription(company_plan, subscription, item, price_id, plan:, interval:)
      replace_older_company_entitlements(company, company_plan)
    end
  end

  def sync_user_subscription(subscription, subscription_metadata, item, price_id)
    user = User.find(subscription_metadata.fetch("user_id"))
    user_plan, interval = user_plan_for_price!(price_id)
    customer_id = value(subscription, "customer")
    known_customer_ids = user.user_subscriptions.where.not(stripe_customer_id: nil).distinct.pluck(:stripe_customer_id)
    raise CustomerMismatch, "Stripe customer does not belong to this user." if known_customer_ids.any? && !known_customer_ids.include?(customer_id)

    user_subscription = user.user_subscriptions.find_by(stripe_subscription_id: value(subscription, "id")) ||
      user.user_subscriptions.where(user_plan:, stripe_subscription_id: nil).order(created_at: :desc, id: :desc).first ||
      user.user_subscriptions.build(user_plan:)
    assign_subscription(user_subscription, subscription, item, price_id, user_plan:, interval:, stripe_customer_id: customer_id)
  end

  def assign_subscription(record, subscription, item, price_id, plan: nil, user_plan: nil, interval:, stripe_customer_id: nil)
    status = event.type == "customer.subscription.deleted" ? "canceled" : value(subscription, "status")
    attributes = {
      stripe_subscription_id: value(subscription, "id"),
      stripe_subscription_item_id: value(item, "id"),
      stripe_price_id: price_id,
      billing_interval: interval,
      status:,
      current_period_start: timestamp(value(subscription, "current_period_start") || value(item, "current_period_start")),
      current_period_end: timestamp(value(subscription, "current_period_end") || value(item, "current_period_end")),
      cancel_at_period_end: value(subscription, "cancel_at_period_end") || false
    }
    attributes[:plan] = plan if plan
    attributes[:user_plan] = user_plan if user_plan
    attributes[:stripe_customer_id] = stripe_customer_id if record.is_a?(UserSubscription)
    record.update!(attributes)
  end

  def replace_older_company_entitlements(company, incoming)
    return unless incoming.entitled?

    newer = company.company_plans.entitled.where.not(id: incoming.id).where("current_period_end > ?", incoming.current_period_end || Time.at(0)).exists?
    return incoming.update!(status: "replaced") if newer

    company.company_plans.entitled.where.not(id: incoming.id).where("current_period_end IS NULL OR current_period_end <= ?", incoming.current_period_end || Time.current).update_all(status: "replaced", updated_at: Time.current)
  end

  def process_invoice(invoice, status)
    subscription_id = value(invoice, "subscription") || value(value(value(invoice, "parent"), "subscription_details"), "subscription")
    return if subscription_id.blank?

    record = CompanyPlan.find_by(stripe_subscription_id: subscription_id) || UserSubscription.find_by(stripe_subscription_id: subscription_id)
    return unless record
    return if record.status.in?(%w[canceled replaced incomplete_expired])

    record.update!(status:)
  end

  def company_for(subscription, subscription_metadata)
    company = Company.find_by(id: subscription_metadata["company_id"])
    company || Company.find_by!(stripe_customer_id: value(subscription, "customer"))
  end

  def company_plan_for_price!(price_id)
    plan = Plan.find_by(stripe_monthly_price_id: price_id)
    return [ plan, "monthly" ] if plan

    [ Plan.find_by!(stripe_annual_price_id: price_id), "annual" ]
  end

  def user_plan_for_price!(price_id)
    plan = UserPlan.find_by(stripe_monthly_price_id: price_id)
    return [ plan, "monthly" ] if plan

    [ UserPlan.find_by!(stripe_annual_price_id: price_id), "annual" ]
  end

  def assert_customer!(known_customer_id, incoming_customer_id)
    return if known_customer_id.blank? || known_customer_id == incoming_customer_id

    raise CustomerMismatch, "Stripe customer does not belong to this account."
  end

  def metadata(object)
    value(object, "metadata")&.to_h&.stringify_keys || {}
  end

  def timestamp(value)
    Time.zone.at(value) if value.present?
  end

  def value(object, key)
    return unless object.respond_to?(:[])

    object[key].nil? ? object[key.to_sym] : object[key]
  end
end
