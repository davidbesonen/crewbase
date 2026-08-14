---
problem_type: domain_modeling_feature
component: job posting type, creation form, staffing workspace, and crew-position authorization
symptoms:
  - a job ambiguously represented either one opening or a multi-role gig
  - company owners could reach crew-position staffing for singular postings
  - existing records needed a safe posting-type classification
  - posting creation did not require an explicit staffing model
tags:
  - rails
  - active-record
  - data-migration
  - authorization
  - forms
---

# Distinguishing single-role jobs from multi-position gigs

## Problem

`Job` represented two different product concepts: a single opening filled by one
person and a larger gig staffed through several roles and headcounts. Because this
distinction was not persisted, every job exposed the same crew-position workspace
and the creation form could not explain which workflow an owner was starting.

## Solution

Persist the concept as a required enum:

```ruby
enum :posting_type, {
  single_role: 0,
  multi_position: 1
}

validates :posting_type, presence: { message: "must be selected" }
```

The job form begins with a required “What are you posting?” choice. “Single job
posting” explains that one person fills one role and no crew workspace is created.
“Multi-position gig” explains that the owner must define an initial position and
headcount, then can add more positions through “Staff This Gig.”

The migration adds the column while nullable, classifies existing jobs, then adds
the database constraints:

```sql
UPDATE jobs
SET posting_type = CASE
  WHEN EXISTS (
    SELECT 1 FROM crew_positions WHERE crew_positions.job_id = jobs.id
  ) THEN 1
  ELSE 0
END
```

Existing jobs with any crew position become multi-position gigs; all others become
single-role postings. The database default remains `single_role` for compatibility
with non-form record creation, but the company job controller clears that default
on `new` and when a create request omits `posting_type`. This ensures the owner form
still requires an intentional selection.

## Enforcing the boundary

Presentation is not the authorization boundary. The job page renders “Staff This
Gig” only for `multi_position?`, while every staffing controller scopes its record
lookup by both company ownership and `posting_type: :multi_position`. Direct GET,
POST, PATCH, or DELETE requests for a single-role posting therefore fail before a
staffing record can be changed.

`CrewPosition` also validates that its job is a multi-position gig. `Job` prevents
conversion to `single_role` while any crew positions remain:

```ruby
def single_role_cannot_have_crew_positions
  return unless single_role? && crew_positions.any?

  errors.add(:posting_type, "cannot be changed while the gig has crew positions")
end
```

## Regression coverage

Tests should keep proving that:

- the required choice appears before the title and neither option is implicit;
- missing form input produces no job;
- both posting types persist correctly;
- a multi-position gig and its required initial position save atomically;
- missing or invalid initial position data persists neither record;
- only multi-position gigs show and permit the staffing workspace;
- direct staffing mutations against single-role postings return 404;
- crew positions cannot belong to single-role postings;
- a gig with positions cannot be converted to a single-role posting;
- legacy jobs are backfilled from the presence of crew positions; and
- fixtures, seeds, completion, and project-based staffing scenarios declare the
  intended type.

The public sharing and invitation rules in
`docs/solutions/security-issues/secure-public-job-sharing-and-tokenized-invitation-auth-handoff.md`
remain compatible: both posting types may be publicly shared, while only
multi-position gigs expose internal crew staffing.

See
`docs/solutions/logic-errors/multi-position-gig-staffing-workflow.md`
for application-pipeline navigation, position-specific acceptance, and the
current creation workflow.
