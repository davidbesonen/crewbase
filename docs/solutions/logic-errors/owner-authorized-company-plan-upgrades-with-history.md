---
problem_type: logic_error
component: company_plan_upgrade_workflow
symptoms:
  - company owners had no direct plan-management entry point
  - plan changes had no centralized authorization or tier-order validation
  - replacing a plan risked losing subscription history
---

# Owner-authorized company plan upgrades with history

## Problem

Pricing tiers and entitlements existed, but an owner could not manage a company's plan from the company workspace. A safe beta flow also needed to distinguish plan activation from payment collection: Crewbase does not yet collect card payments.

## Solution

Expose a company-scoped singleton plan resource and resolve the company through `current_user.owned_companies`. This makes both the plan page and update endpoint owner-only instead of relying on presentation controls.

Use `UpgradeCompanyPlan` as the single write boundary. It verifies that the destination plan is active and strictly higher in `Plan::TIER_RANKS`, then replaces the current assignment and creates the new active assignment in one transaction:

```ruby
CompanyPlan.transaction do
  current_company_plan&.update!(status: "replaced", current_period_end: Time.current)
  company.company_plans.create!(plan:, status: "active", current_period_start: Time.current)
end
```

Preserving the replaced row provides an audit trail and avoids silently rewriting subscription history. The UI links to plan management beside Edit Company in the shared owner navigation, so it appears consistently on the company profile and Company Manager screen. It lists only higher active tiers and states explicitly that beta activation is immediate but no card is charged.

Keep feature access separate from mutation orchestration. `CompanyPlanEntitlement` remains the source of truth for feature and capacity checks after an upgrade; controllers must continue enforcing those checks server-side.

## Verification

- Service tests cover a successful upgrade, history preservation, and rejection of same or lower tiers.
- Controller tests cover owner access, non-owner denial, and the update response.
- Architecture tests ensure the new HAML and component boundaries remain valid.

## Future billing integration

Do not turn this beta action into a charge by adding payment calls inside the controller. Introduce a billing service and idempotent provider webhook flow, and activate paid entitlements only from verified billing state. The current workflow is deliberately honest about not collecting payment.

## Related solutions

- [Company owner staffing analytics and truthful Studio benefits](../integration-issues/company-owner-staffing-analytics-and-truthful-studio-benefits.md)
- [Distinguishing single-role jobs from multi-position gigs](distinguishing-single-role-jobs-from-multi-position-gigs.md)
- [Multi-position gig staffing workflow](multi-position-gig-staffing-workflow.md)
