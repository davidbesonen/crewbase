---
problem_type: logic_error
component: employer staffing and application pipeline
symptoms:
  - searchable crew filters treated empty-state prompts as entered search text
  - application review lost the staffing-page navigation context
  - accepting a gig applicant did not fill a specific crew position
  - multi-position gigs could be created without a position or headcount
tags:
  - multi-position-gigs
  - crew-staffing
  - application-pipeline
  - searchable-combobox
  - nested-attributes
  - contextual-navigation
  - position-assignment
---

# Keep multi-position gig creation, applications, and staffing connected

## Problem

Gig creation, application review, and crew staffing behaved like adjacent
features instead of one continuous owner workflow. A gig could be published
without defining its staffing structure, accepting an applicant only changed an
application status, and navigating to the application pipeline discarded the
staffing context. The crew-search comboboxes also placed prompts such as “Any
skill” into the searchable value.

## Creation invariant

An owner-created multi-position gig must include its first position and positive
integer headcount. `Job` accepts nested `crew_positions_attributes`, and the
company job form conditionally enables the required fields only when
`posting_type` is `multi_position`. The job and position save in the existing
transaction, so an invalid position leaves neither record persisted.

The creation-only enforcement flag preserves legacy and internal record creation,
while the permanent domain boundary still prevents a single-role job from owning
crew positions. Editing an existing gig does not require resubmitting its first
position.

## Atomic position-specific acceptance

`AcceptJobApplication` is the transaction boundary for accepting an applicant.
For a multi-position gig it:

1. Requires a `CrewPosition` belonging to the application’s job.
2. Locks that position and rechecks available headcount.
3. Creates the `CrewAssignment`.
4. Marks the application accepted with reviewer and decision timestamps.

```ruby
crew_position.with_lock do
  return failure("That position is already fully staffed.") unless position_has_room?

  crew_position.crew_assignments.create!(profile: application.profile)
  accept_application!
end
```

Any record failure rolls both writes back. The application pipeline and the
individual application review submit `status=accepted` and `crew_position_id` to
the same controller action. Single-role acceptance continues through the
status-only path and never creates a crew assignment.

Available positions are prepared by the query/controller and preloaded with
assignments; HAML and components do not construct Active Record queries.

## Safe contextual navigation

The staffing page links to the pipeline with the fixed token
`return_to=staffing` and the current `job_id`. The applications controller builds
the return destination itself only when that job belongs to the already
owner-scoped company and is a multi-position gig:

```ruby
return unless params[:return_to] == "staffing" && job_id

job = @company.jobs.find_by(id: job_id)
return unless job&.multi_position?

{ path: usr_job_crew_path(job), label: "Back to Staff This Gig" }
```

The pipeline preserves this allowlisted context through stage, filter, and clear
links. It never renders or redirects to a caller-supplied URL.

## Empty combobox prompts are not values

Crew-search inputs render blank when no filter is selected and use “Any …” only
as placeholder guidance. A selected real option still appears as the input
value, and choosing the blank option clears both the visible text and backing
selection.

```haml
= search_field_tag "#{field[:name]}_search",
  selected_filter_label(field),
  placeholder: field[:blank_label],
  role: "combobox"
```

The backing native select preserves the existing GET parameter contract, while
the Stimulus controller maintains filtering, keyboard navigation, and ARIA
state.

## Regression strategy

Keep coverage at the observable boundaries:

- Model and controller tests prove a gig and its initial position save
  atomically, invalid or omitted position data persists nothing, and single-role
  creation remains unchanged.
- Service tests prove missing, wrong-job, and full positions do not accept or
  assign an applicant, while a valid selection performs both writes.
- Controller and component tests prove both review screens offer eligible
  positions for gigs, omit the selector for single-role jobs, and reject
  unauthorized mutations.
- Navigation tests prove the staffing back link appears only for the recognized,
  authorized staffing context and survives pipeline filters.
- Combobox tests prove blank inputs use placeholder text, real selections are
  restored, and clearing does not turn the prompt into query text.

Capacity shown in the UI is guidance only. Always recheck it during the locked
write so concurrent requests cannot overstaff a position.

## Related solutions

- [Distinguishing single-role jobs from multi-position gigs](distinguishing-single-role-jobs-from-multi-position-gigs.md)
- [Semantic buttons and job taxonomy multi-comboboxes](../ui-bugs/semantic-buttons-and-job-taxonomy-multicombobox.md)
- [Secure public job sharing and tokenized invitation auth handoff](../security-issues/secure-public-job-sharing-and-tokenized-invitation-auth-handoff.md)
