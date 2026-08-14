require "test_helper"

class ProcessStripeEventTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    owner = User.create!(first_name: "Webhook", last_name: "Owner", email: "webhook-owner@example.com", password: "password123")
    industry = Industry.create!(name: "Webhook Billing")
    @company = Company.create!(name: "Webhook Billing Company", contact_email: "webhooks@example.com", industries: [ industry ])
    @company.company_assignments.create!(user: owner, role: "owner")
    @plan = Plan.create!(
      key: "webhook-team",
      name: "Webhook Team",
      active: true,
      monthly_price_cents: 4_900,
      annual_price_cents: 49_000,
      stripe_monthly_price_id: "price_webhook_monthly",
      data: {}
    )
  end

  test "records Checkout completion once and attaches the Stripe customer to the company" do
    event = stripe_event(
      id: "evt_checkout",
      type: "checkout.session.completed",
      object: { "customer" => "cus_company", "metadata" => { "company_id" => @company.id.to_s } }
    )

    ProcessStripeEvent.new(event:).call
    ProcessStripeEvent.new(event:).call

    assert_equal "cus_company", @company.reload.stripe_customer_id
    assert_equal 1, StripeEvent.where(stripe_event_id: "evt_checkout").count
    assert StripeEvent.find_by!(stripe_event_id: "evt_checkout").processed_at.present?
  end

  test "synchronizes the local company subscription from Stripe's current state" do
    period_start = Time.utc(2026, 8, 1)
    period_end = Time.utc(2026, 9, 1)
    event = stripe_event(
      id: "evt_subscription",
      type: "customer.subscription.updated",
      object: {
        "id" => "sub_company",
        "customer" => "cus_company",
        "status" => "active",
        "cancel_at_period_end" => false,
        "current_period_start" => period_start.to_i,
        "current_period_end" => period_end.to_i,
        "metadata" => {
          "company_id" => @company.id.to_s,
          "plan_id" => @plan.id.to_s,
          "billing_interval" => "monthly"
        },
        "items" => { "data" => [ { "id" => "si_company", "price" => { "id" => "price_webhook_monthly" } } ] }
      }
    )

    ProcessStripeEvent.new(event:).call

    subscription = @company.company_plans.find_by!(stripe_subscription_id: "sub_company")
    assert_equal @plan, subscription.plan
    assert_equal "si_company", subscription.stripe_subscription_item_id
    assert_equal "price_webhook_monthly", subscription.stripe_price_id
    assert_equal "monthly", subscription.billing_interval
    assert_equal "active", subscription.status
    assert_equal period_start, subscription.current_period_start
    assert_equal period_end, subscription.current_period_end
  end

  test "uses the Stripe price rather than spoofed plan metadata" do
    other_plan = Plan.create!(key: "webhook-studio", name: "Webhook Studio", active: true, monthly_price_cents: 9_900, annual_price_cents: 99_000, stripe_monthly_price_id: "price_webhook_studio", data: {})
    event = stripe_event(
      id: "evt_price_authority",
      type: "customer.subscription.updated",
      object: subscription_object("sub_price", "si_price", "price_webhook_monthly", { "plan_id" => other_plan.id.to_s })
    )

    ProcessStripeEvent.new(event:).call

    assert_equal @plan, @company.company_plans.find_by!(stripe_subscription_id: "sub_price").plan
  end

  test "rejects a subscription whose Stripe customer belongs to another company" do
    @company.update!(stripe_customer_id: "cus_expected")
    event = stripe_event(
      id: "evt_wrong_customer",
      type: "customer.subscription.updated",
      object: subscription_object("sub_wrong", "si_wrong", "price_webhook_monthly", {}, customer: "cus_attacker")
    )

    assert_raises(ProcessStripeEvent::CustomerMismatch) { ProcessStripeEvent.new(event:).call }
    assert_nil StripeEvent.find_by!(stripe_event_id: "evt_wrong_customer").processed_at
    assert_nil @company.company_plans.find_by(stripe_subscription_id: "sub_wrong")
  end

  test "synchronizes crew premium subscription metadata" do
    user = User.create!(first_name: "Crew", last_name: "Premium", email: "crew-premium-webhook@example.com", password: "password123")
    user_plan = UserPlan.create!(name: "Crewbase Pro", slug: "crewbase-pro-webhook", monthly_price_cents: 700, annual_price_cents: 7_000, stripe_monthly_price_id: "price_crew_monthly")
    event = stripe_event(
      id: "evt_crew_subscription",
      type: "customer.subscription.created",
      object: {
        "id" => "sub_crew", "customer" => "cus_crew", "status" => "active",
        "metadata" => { "user_id" => user.id.to_s, "user_plan_id" => "999999", "billing_interval" => "monthly" },
        "items" => { "data" => [ { "id" => "si_crew", "price" => { "id" => "price_crew_monthly" } } ] }
      }
    )

    ProcessStripeEvent.new(event:).call

    subscription = user.user_subscriptions.find_by!(stripe_subscription_id: "sub_crew")
    assert_equal user_plan, subscription.user_plan
    assert_equal "cus_crew", subscription.stripe_customer_id
    assert_equal "active", subscription.status
  end

  test "invoice failure and recovery synchronize access status" do
    company_plan = @company.company_plans.create!(plan: @plan, status: "active", stripe_subscription_id: "sub_invoice", stripe_subscription_item_id: "si_invoice")

    ProcessStripeEvent.new(event: stripe_event(id: "evt_failed", type: "invoice.payment_failed", object: { "subscription" => "sub_invoice" })).call
    assert_equal "past_due", company_plan.reload.status

    ProcessStripeEvent.new(event: stripe_event(id: "evt_paid", type: "invoice.paid", object: { "subscription" => "sub_invoice" })).call
    assert_equal "active", company_plan.reload.status
  end

  private

  def stripe_event(id:, type:, object:)
    Stripe::Event.construct_from("id" => id, "type" => type, "data" => { "object" => object })
  end


  def subscription_object(subscription_id, item_id, price_id, metadata_overrides = {}, customer: "cus_company")
    {
      "id" => subscription_id,
      "customer" => customer,
      "status" => "active",
      "metadata" => {
        "company_id" => @company.id.to_s,
        "plan_id" => @plan.id.to_s,
        "billing_interval" => "monthly"
      }.merge(metadata_overrides),
      "items" => { "data" => [ { "id" => item_id, "price" => { "id" => price_id } } ] }
    }
  end
end
