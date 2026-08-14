---
problem_type: integration_feature
component: public job sharing, email invitations, authentication handoff, and changelog publishing
symptoms:
  - company owners could invite only existing Crewbase profiles
  - open job postings had no public, copyable sharing URL
  - invited people without accounts could not preserve their invitation through authentication
  - prospective users had no public, plain-language record of product updates
---

# Secure public job sharing and invitation handoff

## Problem

The original invitation flow required an existing `Profile`, while job details lived
behind authenticated `/usr` routes. An external recipient therefore had no public
posting to inspect, no email-addressed invitation to claim, and no durable return
path through sign-up or sign-in.

## Solution

Allow `JobInvitation` to identify its recipient by either `profile` or normalized
`email`. Give every invitation an indexed `has_secure_token` token, but do not treat
token possession alone as authorization: `claim!` must compare the signed-in user's
canonical email before attaching that user's profile.

```ruby
belongs_to :profile, optional: true
has_secure_token

def claim!(user)
  raise ActiveRecord::RecordNotFound unless email.present? && email.casecmp?(user.email)

  update!(profile: user.profiles.find_or_create_by!(profile_type: "user"))
end
```

Keep creation in the existing `JobInvitationCreator`. Known profiles receive the
existing in-app notification; email-only recipients receive a mailer containing
the tokenized public invitation URL. Scope owner-created email invitations directly
to active, published jobs belonging to companies owned by `current_user`.

Use two public entry points with different security properties:

- A shareable posting URL is intentionally public but resolves only active,
  published jobs and exposes recruiting-safe fields.
- A personal invitation URL resolves only an unguessable token. Acceptance requires
  authentication and a recipient profile whose user matches the invitation email.

Store the server-generated relative public path in `session[:return_to_after_auth]`
when a guest visits either page. Consume and delete it in Devise's post-sign-in or
post-sign-up hook so authentication returns the visitor to the original intent
without creating a sticky or user-controlled redirect.

The public changelog is a separate publication boundary. `ChangeLogEntry.published`
includes only entries whose `published_at` is at or before the current time and
orders them deterministically newest first. Admin CRUD remains role-gated; the
public `/changelog` endpoint is read-only and unauthenticated.

## Regression coverage

Keep controller and service coverage for:

- public access to active published jobs and 404 responses for unpublished jobs;
- owner-only email invitations and mail containing the tokenized path;
- guest sign-up/sign-in choices and return to the same invitation after sign-in;
- successful claim by a matching email and denial without mutation for a different
  signed-in email;
- existing profile invitation notifications and active-job validation;
- newest-first public changelog entries with drafts excluded;
- admin publication of changelog entries; and
- the repository's HAML query boundary.

## Prevention and future hardening

Always repeat posting eligibility checks when an application is started or
submitted, because a public page can become stale. Keep return paths
server-generated and relative. If they ever become parameter-driven, enforce an
internal-path allowlist.

Before adding invitation expiry, revocation, or resend behavior, define the state
transitions and mail retry semantics explicitly. Also handle the collision where a
profile invitation and an email invitation for the same job converge on one
profile; the database uniqueness constraint should remain the final concurrency
guard, but the application should merge or reuse the existing invitation rather
than return a 500.

The related UI guidance in
`docs/solutions/ui-bugs/semantic-buttons-and-job-taxonomy-multicombobox.md` remains
consistent with this implementation. No existing solution was superseded.
