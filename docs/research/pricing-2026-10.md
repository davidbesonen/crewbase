# Affordable launch pricing — October 8, 2026

Crewbase uses free crew accounts and two company plans. Both company plans include the implemented staffing workflow; the paid plan increases capacity rather than charging to review applicants or granting preferred ranking.

| Plan | USD price | Company users | Active jobs | Active projects |
| --- | --- | --- | --- | --- |
| Starter | Free | 2 | 2 | 1 |
| Team | $19/month or $190/year | 5 | 15 | Unlimited |

Annual billing saves $38 against 12 monthly payments (16.7%). Annual totals are shown explicitly. No application credits, per-hire charges, paid ranking boosts, introductory discount conditions, or new paid crew memberships. Crewbase does not process wages; this is subscription pricing for hiring tools.

## Competitor evidence

Official pages reviewed October 8, 2026. Regional availability, promotions, and prices can change.

- [Staff Me Up pricing](https://staffmeup.com/pricing/): crew Premium is $19.99/month or $149.99/year, including unlimited applications and work alerts. Its [employer help](https://support.staffmeup.com/en/articles/11722369) also describes a free job-poster plan. Lesson: allow low-friction entry; avoid a crew application paywall while Crewbase builds supply and demand.
- [Indeed employer pricing](https://www.indeed.com/hire/resources/howtohub/how-pricing-works-on-indeed): limited free job postings with paid promotion based on engagement. [Its pricing page](https://www.indeed.com/hire/cs/pricing) lists sponsored budgets starting at $5/day or $150/month, with market-dependent minimums. Lesson: free employer entry is familiar, but advertising spend is less predictable for small crews than a flat subscription.
- [Upwork client fees](https://support.upwork.com/hc/en-us/articles/4660220468499-What-is-the-Client-Marketplace-Fee): Basic clients pay up to 7.99% on freelancer payments. [Freelancer fees](https://support.upwork.com/hc/en-us/articles/211062538-Learn-about-the-Freelancer-Service-Fee) range from 0–15% per contract. Lesson: transaction fees fund payment-related services. Crewbase should not copy that model without providing wage payments and their associated protections.

This is a launch hypothesis, not a revenue forecast. Measure active companies, repeat hiring, capacity-limit encounters, upgrade conversion, support cost, and retention before adding tiers. The $19 price positions Crewbase as a low-commitment workflow tool; it does not promise the reach or hiring results of established marketplaces.

## Rollout and existing accounts

`PricingCatalog` is the source for public pricing and the idempotent `InstallPricingCatalog` installer. The migration installs versioned `free` and `team_2026` rows. Seed setup uses the same definitions.

Old company plans and Crew Pro are retired from new sales. Existing subscription records, old prices, price IDs, and webhook reconciliation remain intact. No remote Stripe subscription is changed or canceled by the migration. Existing subscribers retain billing-portal access. When no paid company entitlement remains, the active Starter catalog provides free access; existing jobs and records are not deleted. Capacity checks apply to new/activated work.

Configure **new** Stripe USD recurring prices on `team_2026`: monthly $19 and yearly $190. Leave old mappings intact. The UI offers only configured intervals; until setup is complete it clearly states that paid upgrades are unavailable. No live Stripe prices or charges were created during this implementation. Verify checkout, webhook confirmation, renewal, cancellation, and portal behavior in Stripe test mode before enabling paid sales.

Free setup does not contact Stripe or expire as a trial. Paid access still depends on confirmed webhook state. Existing subscriptions are not silently moved to the new rate. Old subscribers can review their existing plan and cancellation settings in billing management.
