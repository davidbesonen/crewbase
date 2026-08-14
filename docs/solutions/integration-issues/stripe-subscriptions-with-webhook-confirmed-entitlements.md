---
problem_type: integration_issue
component: stripe_company_and_crew_subscriptions
symptoms:
  - selecting a paid tier granted local access without confirmed payment
  - company subscriptions had no secure checkout, portal, or provider lifecycle synchronization
  - company and individual subscription identities could be confused without separate domains
---

# Stripe subscriptions with webhook-confirmed entitlements

## Problem

Paid plans were represented locally, but plan selection immediately activated access. A browser redirect is not proof of payment, and subscription status can later change because of failed renewals, cancellation, or portal activity.

## Solution

Use Stripe-hosted Checkout for card collection and the Stripe Customer Portal for payment methods, invoices, and cancellation. The application never receives raw card details.

Keep company and crew subscriptions separate: `CompanyPlan` belongs to a company, while `UserSubscription` belongs to an individual user. Both store Stripe customer, subscription, item, price, interval, status, period, and cancellation state.

Treat signed Stripe webhooks as the entitlement authority. `ProcessStripeEvent` verifies identity using the known Stripe price, dispatches company versus crew metadata, validates customer ownership, and changes local access only for `active` or `trialing` subscriptions. Failed invoices move access to `past_due`; successful invoices restore it.

Persist every Stripe event ID with a unique index and lock it during processing. This makes webhook retries idempotent. Preserve failed/mismatched events as unprocessed so Stripe retries them and operators can investigate.

For company upgrades, update the existing Stripe subscription item with payment-safe prorations instead of creating a second subscription. Do not replace the current local entitlement until Stripe reports the new active subscription state.

## Security invariants

- Never trust plan IDs or prices posted by the browser.
- Resolve the subscribed product from a configured Stripe Price ID.
- Reject a Stripe customer that conflicts with an already-bound company or user.
- Never activate access from a Checkout success URL.
- Verify webhook signatures against the raw request body.
- Filter card, payment-method, secret, token, and signature parameters from logs.

## Verification

Tests cover hosted Checkout, owner scoping, portal access, signature rejection, event replay, company and crew dispatch, spoofed metadata, customer mismatch, subscription upgrades, invoice failure/recovery, and entitlement status semantics.

## Related solution

- [Owner-authorized company plan upgrades with history](../logic-errors/owner-authorized-company-plan-upgrades-with-history.md)
