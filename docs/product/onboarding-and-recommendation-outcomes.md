# Onboarding and recommendation outcomes

New members choose **Find work**, **Hire crew**, or **Both** at `/usr/onboarding`.
Workers may select up to eight occupations immediately; further profile details
remain available through the profile editor. Quick start does not publish an
unfinished profile. Hiring-only members without a company continue to company
creation. Settings provides a way to revisit the choice.

Dashboard recommendations provide **Not interested?** with relevance, location,
pay, or timing feedback. A dismissal hides that job for that member from both
dashboard recommendations and matching notification emails. Hidden recommendations
can be restored. Feedback does not change another member's results or silently
rewrite profile attributes or scoring weights.

The administrator-only `/admin/product_metrics` page summarizes the last 30 days:
onboarding, profile completion, recommendation impressions and visits,
applications, published jobs, offers and booking decisions. Events contain record
IDs and action names, not message bodies, search terms, or profile text. Dashboard
impressions and recommendation visits are deduplicated per member/job/day.

Applications and accepted offers are associated with a recommendation only when
the same member previously saw that job recommended within 30 days. This is
observational attribution, not proof that the recommendation caused the outcome.
Use real pilot outcomes and dismissal reasons to decide future scoring changes.

`test/data/recommendation_scenarios.yml` supplies eight synthetic industry cases.
The regression suite checks occupation-derived capabilities and explicit equipment
requirements against full and partial matches. These cases protect known matching
rules; they do not establish accuracy for every occupation or real-world hiring.

Related implementation and launch notes:

- [Booking confirmation](booking-confirmation.md)
- [Trust and moderation](trust-and-moderation.md)
- [Operations and production verification](../operations/production-readiness.md)
