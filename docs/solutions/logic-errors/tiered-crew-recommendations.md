---
problem_type: logic_error
component:
  - crew_recommender
  - staffing_ui
  - seed_data
symptoms:
  - valid candidates disappeared after failing any required criterion
  - companies could not distinguish exact matches from near matches
  - staffing controls obscured why each candidate was eligible
  - random seed data frequently produced no recommendations
tags:
  - rails
  - recommendations
  - tiered-ranking
  - availability
  - staffing-modal
  - deterministic-seeds
---

# Tiered crew recommendations with explainable gaps

## Problem

`CrewRecommender` treated an availability conflict or any missing required taxonomy item as an absolute exclusion. Strong candidates therefore disappeared instead of being presented as useful near matches. Random seed taxonomy and large random calendar blockouts also made it common for demo companies to receive no recommendations.

The staffing UI compounded the problem by presenting candidate names in selects without explaining whether each person came from an application, shortlist, or recommendation.

## Solution

Separate eligibility gaps from relevance scoring. A result has a `tier` and `gap_reasons`: zero gaps is a full match, exactly one gap is a near match, and more than one gap remains excluded. Full matches preserve the prior eligibility rules and always sort before near matches.

```ruby
CrewRecommender::Result
# tier: :full or :near
# gap_reasons: Array<String>

return if gap_reasons.size > 1

tier = gap_reasons.empty? ? :full : :near
```

Use the same tier-first sort key for aggregate results, per-job results, and best-match selection:

```ruby
[result.tier == :full ? 0 : 1, -result.score, result.profile.id]
```

Recommendation cards render near matches in amber and show the concrete gap, such as a conflicting date or one missing required occupation, skill, or equipment. Full-match availability remains green.

`JobCrewCandidateQuery` remains the single source for staffing candidates and exposes render-ready rows with all inclusion reasons: application status, named shortlist membership, and full or near recommendation evidence. Assignment and replacement selects were replaced with accessible modal tables, while preserving the existing form endpoints and candidate exclusions.

Seed data now creates deterministic cohorts for each company's earliest published job:

- one non-owner with every required taxonomy item and no job-date conflict;
- one non-owner with every required taxonomy item and exactly two conflicting start dates.

This guarantees both tiers are visible without depending on random profile attributes or calendars.

## Regression strategy

Test tier classification independently from ranking:

- exact eligibility produces a full result with no gaps;
- one missing required taxonomy item or one availability conflict produces a near result with explicit evidence;
- multiple gaps remain excluded;
- full results sort ahead of near results regardless of score;
- job and dashboard cards use non-green near-match styling and show gap text;
- staffing modals aggregate every inclusion reason and exclude already assigned people;
- seed verification guarantees a full and availability-based near match for every seeded company.

Keep database queries out of HAML and render the staffing modal as a sibling component so data dependencies and component composition remain explicit.

## Related solutions

- [Multi-position gig staffing workflow](multi-position-gig-staffing-workflow.md)
- [Distinguishing single-role jobs from multi-position gigs](distinguishing-single-role-jobs-from-multi-position-gigs.md)
- [Semantic buttons and job taxonomy multicombobox](../ui-bugs/semantic-buttons-and-job-taxonomy-multicombobox.md)
